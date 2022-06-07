// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation
import os
import UserNotifications

class DeliveryMechanismNotification {
    let logger = Logger()
    var currentNotificationIdentifier: String?
}

extension DeliveryMechanismNotification: DeliveryMechanism {
    func present(title: String, body: String) {
        let content = UNMutableNotificationContent()

        content.title = title
        content.body = body

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
