// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

/// Protocol to abstract different delivery mechanisms for providing tap
/// reminders.
protocol DeliveryMechanism {
    /// Called when scdaemon's response exceeds the configured timeout. The
    /// dismiss function is not guaranteed to be called before this function is
    /// called again.
    mutating func present(title: String, body: String)

    /// Called on any scdaemon response. The present function is not guaranteed
    /// to be called before this function. The DeliveryMechanism implementation
    /// should store internal state on whether or not a true dismissal is
    /// necessary.
    mutating func dismiss()
}
