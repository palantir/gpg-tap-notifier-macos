// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

public enum ReminderDeliveryMechanismOption: Int, CaseIterable {
    case notificationCenter = 1
    case alert
}

extension ReminderDeliveryMechanismOption : Identifiable {
    public var id: Self { self }
}

extension ReminderDeliveryMechanismOption: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notificationCenter: return "Notification"
        case .alert: return "System Alert"
        }
    }
}
