// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import GpgTapNotifierUserDefaults

struct DeliveryMechanismChoicePreviewView: View {
    var option: ReminderDeliveryMechanismOption

    var notificationCenterPreview: some View {
        return ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .size(width: 100, height: 56)
                .fill(Color.gray)

            // Menubar
            Rectangle()
                .size(width: 100, height: 5)
                .fill(.white)

            // Notification
            RoundedRectangle(cornerRadius: 1)
                .offset(x: 65, y: 10)
                .size(width: 30, height: 8)
                .fill(.white)
                .cornerRadius(1)
                .shadow(radius: 2)
        }
        .frame(width: 100, height: 56, alignment: .center)
        .cornerRadius(3)
    }

    var alertPreview: some View {
        return ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .size(width: 100, height: 56)
                .fill(Color.gray)

            // Menubar
            Rectangle()
                .size(width: 100, height: 5)
                .fill(.white)

            // Alert
            RoundedRectangle(cornerRadius: 2)
                .offset(x: 40, y: 15)
                .size(width: 20, height: 23)
                .fill(.white)
                .shadow(radius: 1)
        }
        .frame(width: 100, height: 56, alignment: .center)
        .cornerRadius(3)
    }

    var body: some View {
        switch option {
        case .notificationCenter: notificationCenterPreview
        case .alert: alertPreview
        }
    }
}

struct DeliveryMechanismChoicePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach(ReminderDeliveryMechanismOption.allCases) {
                DeliveryMechanismChoicePreviewView(option: $0)
                    .padding()
            }
        }
    }
}
