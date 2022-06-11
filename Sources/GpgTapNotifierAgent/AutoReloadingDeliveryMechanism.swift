// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation
import GpgTapNotifierUserDefaults

class AutoReloadingDeliveryMechanism {
    private var cachedDeliveryMechanism: CachedDeliveryMechansim?

    func get() -> DeliveryMechanism {
        let currentDeliveryMechanismOption = readCurrentDeliveryMechanismOption()
        if let cached = cachedDeliveryMechanism, cached.optionValue == currentDeliveryMechanismOption {
            return cached.deliveryMechanism
        }

        // If the user changes the config value while a reminder notification is
        // still shown, we should take care to close it and not leave it on the
        // the screen forever.
        cachedDeliveryMechanism?.deliveryMechanism.dismiss()

        let deliveryMechanism = mapReminderToDeliveryMechanism(currentDeliveryMechanismOption)
        cachedDeliveryMechanism = CachedDeliveryMechansim(
            deliveryMechanism: deliveryMechanism,
            optionValue: currentDeliveryMechanismOption)

        return deliveryMechanism
    }
}

private struct CachedDeliveryMechansim  {
    var deliveryMechanism: DeliveryMechanism
    let optionValue: ReminderDeliveryMechanismOption
}

private func mapReminderToDeliveryMechanism(_ option: ReminderDeliveryMechanismOption) -> DeliveryMechanism {
    switch option {
    case .notificationCenter: return DeliveryMechanismNotification()
    case .alert: return DeliveryMechanismAlert()
    }
}

private func readCurrentDeliveryMechanismOption() -> ReminderDeliveryMechanismOption {
    let storedValue = AppUserDefaults.suite?.integer(forKey: AppUserDefaults.reminderDeliveryMechanism.key)
    return storedValue
        .flatMap { ReminderDeliveryMechanismOption(rawValue: $0) }
        ?? AppUserDefaults.reminderDeliveryMechanism.getDefault()
}
