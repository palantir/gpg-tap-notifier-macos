// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import GpgTapNotifierUserDefaults

struct DeliveryMechanismChooserView: View {
    @AppStorage(AppUserDefaults.reminderDeliveryMechanism.key, store: AppUserDefaults.suite)
    var reminderDeliveryMechanism = AppUserDefaults.reminderDeliveryMechanism.getDefault()

    // TODO: Describe the various delivery mechanisms.
    // TODO: Provide a way to test a notification.
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Delivery mechanism:")
                Spacer()

                ForEach(ReminderDeliveryMechanismOption.allCases) { option in
                    DeliveryMechanismChoiceView(option, isSelected: option == reminderDeliveryMechanism) {
                        reminderDeliveryMechanism = option
                    }
                }
            }

            Text(optionExplanation)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                DeliveryMechanismTestButtonView()
            }
        }
    }

    var optionExplanation: String {
        switch reminderDeliveryMechanism {
        case .notificationCenter: return "If you're not seeing notifications, please make sure GPG Tap Notifier Agent is allowed to send notification in System Preferences."
        case .alert: return "Tap reminders will be shown as a centered alert similar to other macOS security prompts."
        }
    }
}

struct DeliveryMechanismChooserView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryMechanismChooserView()
    }
}
