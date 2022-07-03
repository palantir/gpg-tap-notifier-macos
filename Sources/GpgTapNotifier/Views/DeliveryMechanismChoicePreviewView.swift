// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import GpgTapNotifierUserDefaults

struct DeliveryMechanismChoicePreviewView: View {
    @Environment(\.colorScheme) var colorScheme

    var option: ReminderDeliveryMechanismOption

    var backgroundColor: Color {
        switch colorScheme {
        case .dark: return Color.init(.sRGB, white: 0.85, opacity: 1)
        case .light: return Color.init(.sRGB, white: 0.92, opacity: 1)
        @unknown default: return Color.init(.sRGB, white: 0.92, opacity: 1)
        }
    }
    var contentColor: Color {
        switch colorScheme {
        case .dark: return Color.gray
        case .light: return Color.white
        @unknown default: return Color.white
        }
    }
    var symbolsColor: Color {
        switch colorScheme {
        case .dark: return Color.primary
        case .light: return Color.primary.opacity(0.6)
        @unknown default: return Color.primary.opacity(0.6)
        }
    }
    var previewBorderColor = Color.gray.opacity(0.5)
    var previewCornerRadius: CGFloat = 3

    var notificationCenterPreview: some View {
        return ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .size(width: 100, height: 56)
                .fill(backgroundColor)

            // Menubar
            Rectangle()
                .size(width: 100, height: 13)
                .fill(contentColor)

            // Menubar Icons
            Image(systemName: "magnifyingglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 7)
                .fixedSize()
                .offset(x: 87, y: 3)
                .foregroundColor(symbolsColor)
            Image(systemName: "wifi")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 7)
                .fixedSize()
                .offset(x: 72, y: 3)
                .foregroundColor(symbolsColor)

            // Preview Border
            RoundedRectangle(cornerRadius: previewCornerRadius)
                .stroke(previewBorderColor, lineWidth: 2)

            // Notification
            RoundedRectangle(cornerRadius: 2)
                .offset(x: 23, y: 20)
                .size(width: 70, height: 20)
                .fill(contentColor)
                .shadow(color: Color.gray.opacity(0.4), radius: 2)

        }
        .frame(width: 100, height: 56, alignment: .center)
        .cornerRadius(previewCornerRadius)
    }

    var alertPreview: some View {
        return ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .size(width: 100, height: 56)
                .fill(backgroundColor)

            // Menubar
            Rectangle()
                .size(width: 100, height: 8)
                .fill(contentColor)

            // Preview Border
            RoundedRectangle(cornerRadius: previewCornerRadius)
                .stroke(previewBorderColor, lineWidth: 2)

            // Alert
            RoundedRectangle(cornerRadius: 2)
                .offset(x: 40, y: 17)
                .size(width: 20, height: 23)
                .fill(contentColor)
                .shadow(radius: 1)
        }
        .frame(width: 100, height: 56, alignment: .center)
        .cornerRadius(previewCornerRadius)
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
            ForEach(ReminderDeliveryMechanismOption.allCases) { option in
                HStack {
                    ForEach(ColorScheme.allCases, id: \.hashValue) { colorScheme in
                        DeliveryMechanismChoicePreviewView(option: option)
                            .padding(5)
                            .colorScheme(colorScheme)
                    }
                }
            }
        }
        .padding(5)
    }
}
