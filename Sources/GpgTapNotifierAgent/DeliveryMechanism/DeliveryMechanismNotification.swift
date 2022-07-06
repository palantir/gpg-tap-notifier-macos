// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation
import os
import UserNotifications

class DeliveryMechanismNotification: NSObject {
    let logger = Logger()
    var didPerformSetup = false
    var requestingNotificationAuthorizationTask: Task<(), Never>?

    struct PresentingState {
        let continuation: CheckedContinuation<PresentStopReason, Never>
        let currentNotificationIdentifier: String
    }

    /// Non-nil if a notification is currently displayed.
    private var presentingState: PresentingState? = nil

    private func getNotificationCategories() -> Set<UNNotificationCategory> {
        let openConfigurationAction = UNNotificationAction(
            identifier: TapReminderActions.openConfiguration.rawValue,
            title: "Open Configuration")
        let category = UNNotificationCategory(
            identifier: NotificationCategories.tapReminder.rawValue,
            actions: [openConfigurationAction],
            intentIdentifiers: [],
            options: .customDismissAction)
        return [category]
    }

    // For some reason .badge permissions are also required for .sound: https://stackoverflow.com/a/70499458
    private let notificationOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .providesAppNotificationSettings]

    private func performSetupIfNecessary() {
        guard !didPerformSetup else {
            return
        }

        // The docs for UNUserNotificationCenterDelegate say the delegate should
        // be set before application:didFinishLaunchingWithOptions returns, but
        // I don't believe this is strictly necessary in practice. As long as
        // the delegate is setup before the delegate is called, actions are
        // handled as expected.
        //
        // We're setting the delegate a bit late since we're not sure if the
        // Notification Center will be used at all. It's possible the agent is
        // configured to use the system alert delivery mechanism.
        UNUserNotificationCenter.current().setNotificationCategories(getNotificationCategories())
        UNUserNotificationCenter.current().delegate = self

        didPerformSetup = true
    }

    private func requestInitialNotificationAuthorization() async {
        if let task = requestingNotificationAuthorizationTask {
            return await task.value
        }

        let task = Task {
            // Intentionally not re-throwing errors or signaling !granted status. This application is expected
            // to continue attempting notification delivery. The user may have changed settings in System Preferences since this point.
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: notificationOptions)
                if !granted {
                    self.logger.error("User did not authorize notifications.")
                }
            } catch {
                self.logger.error("Failed to request permission for notifications: \(error.localizedDescription)")
            }
        }
        self.requestingNotificationAuthorizationTask = task

        return await task.value
    }
}

extension DeliveryMechanismNotification: DeliveryMechanism {
    func present(title: String, body: String) async -> PresentStopReason {
        performSetupIfNecessary()
        await requestInitialNotificationAuthorization()

        if let presentingState = self.presentingState {
            self.presentingState = nil

            // This shouldn't happen in practice, but if the present() function
            // is called multiple times without dismiss(), remove any existing
            // notifications and present a new one. It's not clear if this is the right
            // behavior, but it'll make any new reminders more prominent.
            presentingState.continuation.resume(returning: .reminderReplaced)
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [presentingState.currentNotificationIdentifier])
        }

        let content = UNMutableNotificationContent()

        content.title = title
        content.body = body
        content.categoryIdentifier = NotificationCategories.tapReminder.rawValue

        // Always play a sound by default. Users can disable this in System Preferences.
        // TODO: Consider making what sound plays configurable.
        content.sound = .default

        let currentNotificationIdentifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: currentNotificationIdentifier, content: content, trigger: nil)

        return await withCheckedContinuation { (continuation: CheckedContinuation<PresentStopReason, Never>) in
            let presentingState = PresentingState(continuation: continuation, currentNotificationIdentifier: currentNotificationIdentifier)
            self.presentingState = presentingState

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    self.logger.error("Failed to deliver notification: \(error.localizedDescription)")

                    presentingState.continuation.resume(returning: .deliveryError(error))
                    if self.presentingState?.currentNotificationIdentifier == currentNotificationIdentifier {
                        self.presentingState = nil
                    }
                }
            }
        }
    }

    func dismiss() {
        guard let presentingState = presentingState else {
            return
        }
        self.presentingState = nil

        presentingState.continuation.resume(returning: .dismissed)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [presentingState.currentNotificationIdentifier])
    }

    func setupForReminderTest() async {
        performSetupIfNecessary()
        await requestInitialNotificationAuthorization()
    }
}

extension DeliveryMechanismNotification: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        self.presentingState?.continuation.resume(returning: .userManuallyCleared)
        self.presentingState = nil

        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier, UNNotificationDismissActionIdentifier:
            // No-op if the notification was simply clicked. Let's treat this as
            // a dismiss operation.
            break
        case TapReminderActions.openConfiguration.rawValue:
            openConfigurationApp()
        default:
            logger.error("Encountered unrecongized notification action: \(response.actionIdentifier)")
        }
    }

    // As of macOS Monterey 12.4, I don't believe this method is ever used. It
    // appears to be iOS-specific. Doesn't hurt to declare intent in case a
    // future version of macOS implements this system feature.
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        openConfigurationApp()
    }
}

enum NotificationCategories: String {
    case tapReminder = "TAP_REMINDER"
}

enum TapReminderActions: String {
    case openConfiguration = "OPEN_CONFIGURATION"
}
