// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation
import os
import UserNotifications

class DeliveryMechanismNotification: NSObject {
    let logger = Logger()
    var currentNotificationIdentifier: String?
    var didPerformSetup = false

    private func getNotificationCategories() -> Set<UNNotificationCategory> {
        let openConfigurationAction = UNNotificationAction(
            identifier: TapReminderActions.openConfiguration.rawValue,
            title: "Open Configuration")
        let category = UNNotificationCategory(
            identifier: NotificationCategories.tapReminder.rawValue,
            actions: [openConfigurationAction],
            intentIdentifiers: [])
        return [category]
    }

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

        // For some reason .badge permissions are also required for .sound: https://stackoverflow.com/a/70499458
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if !granted {
                self.logger.error("User did not authorize notifications.")
            }
            if let error = error {
                self.logger.error("Failed to request permission for notifications: \(error.localizedDescription)")
            }
        }

        didPerformSetup = true
    }
}

extension DeliveryMechanismNotification: DeliveryMechanism {
    func present(title: String, body: String) {
        performSetupIfNecessary()

        let content = UNMutableNotificationContent()

        content.title = title
        content.body = body
        content.categoryIdentifier = NotificationCategories.tapReminder.rawValue

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

    func dismiss() {
        guard let identifier = self.currentNotificationIdentifier else {
            return
        }

        self.currentNotificationIdentifier = nil
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

extension DeliveryMechanismNotification: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // No-op if the notification was simply clicked. Let's treat this as
            // a dismiss operation.
            break
        case TapReminderActions.openConfiguration.rawValue:
            openConfigurationApp()
        default:
            logger.error("Encountered unrecongized notification action: \(response.actionIdentifier)")
        }
    }
}

enum NotificationCategories: String {
    case tapReminder = "TAP_REMINDER"
}

enum TapReminderActions: String {
    case openConfiguration = "OPEN_CONFIGURATION"
}
