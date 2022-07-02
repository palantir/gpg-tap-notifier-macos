// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import GpgTapNotifierUserDefaults

struct DeliveryMechanismChoiceView: View {
    var option: ReminderDeliveryMechanismOption
    var isSelected: Bool
    var action: () -> Void

    public init(_ option: ReminderDeliveryMechanismOption, isSelected: Bool, action: @escaping () -> Void) {
        self.option = option
        self.isSelected = isSelected
        self.action = action
    }

    var title: String {
        switch option {
        case .notificationCenter: return "Notification"
        case .alert: return "System Alert"
        }
    }

    var body: some View {
        Button (action: action) {
            VStack {
                DeliveryMechanismChoicePreviewView(option: option)
                Text(title)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 2)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .background(isSelected ? Color.blue.cornerRadius(5) : nil)
            }
        }.buttonStyle(.plain)
    }
}

struct DeliveryMechanismChoiceView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryMechanismChoiceView(
            .notificationCenter,
            isSelected: true) {}
        .padding()
    }
}
