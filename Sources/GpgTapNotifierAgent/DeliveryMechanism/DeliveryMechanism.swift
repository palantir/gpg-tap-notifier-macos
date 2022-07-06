// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

/// Protocol to abstract different delivery mechanisms for providing tap
/// reminders.
protocol DeliveryMechanism {
    /// Called when scdaemon's response exceeds the configured timeout. The
    /// dismiss function is not guaranteed to be called before this function is
    /// called again.
    mutating func present(title: String, body: String) async -> PresentStopReason

    /// Called on any scdaemon response. The present function is not guaranteed
    /// to be called before this function. The DeliveryMechanism implementation
    /// should store internal state on whether or not a true dismissal is
    /// necessary.
    mutating func dismiss()

    /// Any operations needed to finish before a test reminder can be presented.
    mutating func setupForReminderTest() async
}

extension DeliveryMechanism {
    // This is an optional protocol method that no-ops by default.
    func setupForReminderTest() async {
        return
    }
}

enum PresentStopReason {
    /// The reminder was removed from the screen during normal operation. (i.e.
    /// The scdaemon process began responding.)
    case dismissed
    /// The user clicked on the notification (cause it to be cleared) or clicked
    /// the alert dismiss button.
    case userManuallyCleared
    /// There's already a reminder being displayed.
    case existingReminderDisplayed
    /// The current reminder was replaced with a new one.
    case reminderReplaced
    case deliveryError(Error)
}
