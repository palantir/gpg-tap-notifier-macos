// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Copyright (c) 2015 Yubico AB
// Licensed under the Apache License, Version 2.0.

// The Yubico AB copyright is present aove since the logic in this file was
// directly inspired from https://github.com/klali/scdaemon-proxy

import AppKit
import UserNotifications
import Foundation
import os
import GpgTapNotifierUserDefaults

// Astute observers may have noticed that this file implements a "daemon"
// process meant to run windowless in the background, but extends an
// "application" project template meant for a GUI.
//
// It turns out this daemon has to be written as a macOS application (rather
// than a standard binary package) to produce notifications. This was the case
// during initial implementation in March 2022, and is generally mentioned as
// required across online searches (e.g. StackOverflow).

class AppDelegate: NSObject, NSApplicationDelegate {
    let logger = Logger()
    var autoReloadingDeliveryMechanism = AutoReloadingDeliveryMechanism()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let arguments = Array(CommandLine.arguments[1...])
        if (arguments.contains("--gpg-tap-notifier-test-notification")) {
            Task {
                await self.conductReminderTest()
            }
            return
        }

        // TODO: Create a security scoped bookmark for the scdaemon path and read so this agent works when sandboxed.

        // Intentionally not live reloading this value. Stopping scdaemon to spawn a new
        // process mid-request can result in suprising behavior. If this path changes,
        // users are expected to kill this process and restart it.
        let scdaemonPath = AppUserDefaults.suite?.url(forKey: AppUserDefaults.scdaemonPath.key)
            ?? URL(fileURLWithPath:  AppUserDefaults.scdaemonPath.getDefault())

        // TODO: Handle errors in a sandboxed environment where the scdaemon path is not readable yet.

        // TODO: Validate that the executable at scdaemonPath is readlly scdaemon, and display an error notification if not.

        let scdaemonProcess = setupScdaemon(scdaemonPath: scdaemonPath, arguments: arguments)

        logger.debug("Launching scdaemon: \(scdaemonPath.path) \(arguments.joined(separator: " "))")

        do {
            try scdaemonProcess.run()
        } catch {
            self.logger.error("Failed to start scdaemon at \(scdaemonPath.path): \(error.localizedDescription)")
            try? FileHandle.standardError.write(contentsOf: Data("Failed to start scdaemon at \(scdaemonPath.path): \(error.localizedDescription)\n".utf8))
            openScdaemonExecFailAlert(scdaemonPath: scdaemonPath, error: error)
            exit(1)
        }
    }

    private func setupScdaemon(scdaemonPath: URL, arguments: [String]) -> Process {
        // The .double method defaults to 0 if this key hasn't been configured
        // yet. Check for 0 and set it to our default constant value.
        let reminderTimeoutSetting = AppUserDefaults.suite?.double(forKey: AppUserDefaults.reminderTimeout.key) ?? 0
        let reminderTimeoutSecs = reminderTimeoutSetting == 0 ? AppUserDefaults.reminderTimeout.getDefault() : reminderTimeoutSetting

        let scdaemonStdIn = Pipe()
        let scdaemonStdOut = Pipe()
        let scdaemonStdErr = Pipe()

        let scdaemon = Process()
        scdaemon.executableURL = scdaemonPath
        scdaemon.arguments = arguments
        scdaemon.standardInput = scdaemonStdIn
        scdaemon.standardOutput = scdaemonStdOut
        scdaemon.standardError = scdaemonStdErr

        scdaemon.terminationHandler = { process in
            exit(process.terminationStatus)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleReadToEndOfFileCompletion, object: FileHandle.standardInput, queue: .main) { notification in
            scdaemon.terminate()
        }

        var presentReminderTask: Task<(), Error>? = nil

        // On macOS 12, FileHandle provides an async sequence for reading input
        // data. Unfortunately we have to support macOS 11. The logic below can
        // likely be simplified after that requirement is dropped.

        NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: FileHandle.standardInput, queue: .main) { notification in
            // Resetting the notification timeout when the client (gpg-agent)
            // sends multiple messages in a row. During testing, this seems to
            // result in less false positives while not creating any true
            // negatives.
            presentReminderTask?.cancel()

            let data = try! readCompletionResult(notification.userInfo!).get()

            // In testing, data.isEmpty corresponded to EOF. (But it'd be good to verify that.)
            // To forward this EOF, it appears an explicit .close seems to be needed.
            if data.isEmpty {
                // This should cause the scdaemon to close, which will in turn trigger the
                // terminationHandler above and cause our process to exit.
                try! scdaemonStdIn.fileHandleForWriting.close()
                return
            }

            try! scdaemonStdIn.fileHandleForWriting.write(contentsOf: data)

            FileHandle.standardInput.readInBackgroundAndNotify()

            presentReminderTask = Task {
                do {
                    try await Task.sleep(nanoseconds: UInt64(reminderTimeoutSecs * 1_000_000_000))
                } catch is CancellationError {
                    return
                }

                await self.presentReminder()
            }
        }

        NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: scdaemonStdOut.fileHandleForReading, queue: .main) { notification in
            presentReminderTask?.cancel()
            Task { await self.dismissReminder() }

            let data = try! readCompletionResult(notification.userInfo!).get()
            try! FileHandle.standardOutput.write(contentsOf: data)

            scdaemonStdOut.fileHandleForReading.readInBackgroundAndNotify()
        }

        NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: scdaemonStdErr.fileHandleForReading, queue: .main) { notification in
            presentReminderTask?.cancel()
            Task { await self.dismissReminder() }

            let data = try! readCompletionResult(notification.userInfo!).get()
            try! FileHandle.standardError.write(contentsOf: data)

            scdaemonStdErr.fileHandleForReading.readInBackgroundAndNotify()
        }

        FileHandle.standardInput.readInBackgroundAndNotify()
        scdaemonStdOut.fileHandleForReading.readInBackgroundAndNotify()
        scdaemonStdErr.fileHandleForReading.readInBackgroundAndNotify()

        return scdaemon
    }

    @MainActor
    private func conductReminderTest() async {
        defer { NSApplication.shared.terminate(self) }

        var deliveryMechanism = autoReloadingDeliveryMechanism.get()

        // This call may trigger a notification permission request. If that's
        // the case, the agent should not close/exit before the user has acted
        // on the request.
        await deliveryMechanism.setupForReminderTest()

        // Intentionally starting the timeout after the "setupForReminderTest"
        // call above. This races the .present call below, which may finish
        // first.
        let presentTimeoutTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            deliveryMechanism.dismiss()
        }

        let title = "Test Reminder"
        let body = "This is a test reminder from GPG Tap Notifier that will clear after 3 seconds."
        // TODO: Check if there was an error and save it to UserDefaults for GUI to present.
        let _ = await deliveryMechanism.present(title: title, body: body)

        // If the user manually dismissed the reminder, this task may still be
        // running. Cancel it for good measure.
        presentTimeoutTask.cancel()

        // Wait 50ms before exiting the application. Without this delay clicking
        // on a notification to dismiss it intermittently caused macOS to show
        // an alert with the message:
        //
        //   The application "GPG Tap Notifier Agent.app" is not open anymore.
        //
        // This is likely because the process exited before fully handling the
        // UNNotificationResponse event.
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    @MainActor
    private func presentReminder() async {
        // Intentionally reading from UserDefaults on every reminder rather than
        // setting up a Key-Value Observer (KVO). The KVO adds implementation
        // complexity and reminder aren't sent frequently enough to be worth
        // caching.
        let title = AppUserDefaults.suite?.string(forKey: AppUserDefaults.reminderTitle.key) ?? AppUserDefaults.reminderTitle.getDefault()
        let body = AppUserDefaults.suite?.string(forKey: AppUserDefaults.reminderBody.key) ?? AppUserDefaults.reminderBody.getDefault()

        var deliveryMechanism = autoReloadingDeliveryMechanism.get()
        let _ = await deliveryMechanism.present(title: title, body: body)
    }

    @MainActor
    private func dismissReminder() {
        var deliveryMechanism = autoReloadingDeliveryMechanism.get()
        deliveryMechanism.dismiss()
    }
}
