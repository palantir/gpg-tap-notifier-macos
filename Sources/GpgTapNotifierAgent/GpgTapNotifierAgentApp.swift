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
    var currentNotificationIdentifier: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // TODO: Create a security scoped bookmark for the scdaemon path and read so this agent works when sandboxed.

        // Intentionally not live reloading this value. Stopping scdaemon to spawn a new
        // process mid-request can result in suprising behavior. If this path changes,
        // users are expected to kill this process and restart it.
        let scdaemonPath = AppUserDefaults.suite?.url(forKey: AppUserDefaults.scdaemonPath.key)
            ?? URL(fileURLWithPath:  AppUserDefaults.scdaemonPath.getDefault())

        // TODO: Handle errors in a sandboxed environment where the scdaemon path is not readable yet.

        // TODO: Is there a better way to request notification permissions?
        // For some reason .badge permissions are also required for .sound: https://stackoverflow.com/a/70499458
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if !granted {
                self.logger.error("User did not authorize notifications.")
            }
            if let error = error {
                self.logger.error("Failed to request permission for notifications: \(error.localizedDescription)")
            }
        }

        // TODO: Validate that the executable at scdaemonPath is readlly scdaemon, and display an error notification if not.

        let arguments = Array(CommandLine.arguments[1...])
        let scdaemonProcess = setupScdaemon(scdaemonPath: scdaemonPath, arguments: arguments)

        logger.debug("Launching scdaemon: \(scdaemonPath.path) \(arguments.joined(separator: " "))")

        do {
            try scdaemonProcess.run()
        } catch {
            self.logger.error("Failed to start scdaemon at \(scdaemonPath.path): \(error.localizedDescription)")
            try? FileHandle.standardError.write(contentsOf: Data("Failed to start scdaemon at \(scdaemonPath.path): \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    private func setupScdaemon(scdaemonPath: URL, arguments: [String]) -> Process {
        // The .double method defaults to 0 if this key hasn't been configured
        // yet. Check for 0 and set it to our default constant value.
        let notificationTimeoutSetting = AppUserDefaults.suite?.double(forKey: AppUserDefaults.notificationTimeoutSecs.key) ?? 0
        let notificationTimeoutSecs = notificationTimeoutSetting == 0 ? AppUserDefaults.notificationTimeoutSecs.getDefault() : notificationTimeoutSetting

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

        var notificationTask: Task<(), Error>? = nil

        // On macOS 12, FileHandle provides an async sequence for reading input
        // data. Unfortunately we have to support macOS 11. The logic below can
        // likely be simplified after that requirement is dropped.

        NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: FileHandle.standardInput, queue: .main) { notification in
            // Resetting the notification timeout when the client (gpg-agent)
            // sends multiple messages in a row. During testing, this seems to
            // result in less false positives while not creating any true
            // negatives.
            notificationTask?.cancel()

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

            notificationTask = Task {
                do {
                    try await Task.sleep(nanoseconds: UInt64(notificationTimeoutSecs * 1_000_000_000))
                } catch is CancellationError {
                    return
                }

                self.sendNotification()
            }
        }

        NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: scdaemonStdOut.fileHandleForReading, queue: .main) { notification in
            notificationTask?.cancel()
            self.removeDeliveredNotification()

            let data = try! readCompletionResult(notification.userInfo!).get()
            try! FileHandle.standardOutput.write(contentsOf: data)

            scdaemonStdOut.fileHandleForReading.readInBackgroundAndNotify()
        }

        NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: scdaemonStdErr.fileHandleForReading, queue: .main) { notification in
            notificationTask?.cancel()
            self.removeDeliveredNotification()

            let data = try! readCompletionResult(notification.userInfo!).get()
            try! FileHandle.standardError.write(contentsOf: data)

            scdaemonStdErr.fileHandleForReading.readInBackgroundAndNotify()
        }

        FileHandle.standardInput.readInBackgroundAndNotify()
        scdaemonStdOut.fileHandleForReading.readInBackgroundAndNotify()
        scdaemonStdErr.fileHandleForReading.readInBackgroundAndNotify()

        return scdaemon
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()

        // Intentionally reading from UserDefaults on every notification rather than
        // setting up a Key-Value Observer (KVO). The KVO adds implementation complexity
        // and notifications aren't sent frequently enough to be worth caching.
        content.title = AppUserDefaults.suite?.string(forKey: AppUserDefaults.notificationTitle.key) ?? AppUserDefaults.notificationTitle.getDefault()
        content.body = AppUserDefaults.suite?.string(forKey: AppUserDefaults.notificationBody.key) ?? AppUserDefaults.notificationBody.getDefault()

        // Always play a sound by default. Users can disable this in System Preferences.
        // TODO: Consider making what sound plays configurable.
        content.sound = .default

        let currentNotificationIdentifier = UUID().uuidString
        self.currentNotificationIdentifier = currentNotificationIdentifier
        let request = UNNotificationRequest(identifier: currentNotificationIdentifier, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to deliver notification: \(error.localizedDescription)")

                if self.currentNotificationIdentifier == currentNotificationIdentifier {
                    self.currentNotificationIdentifier = nil
                }
            }
        }
    }

    private func removeDeliveredNotification() {
        guard let identifier = self.currentNotificationIdentifier else {
            return
        }

        self.currentNotificationIdentifier = nil
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
