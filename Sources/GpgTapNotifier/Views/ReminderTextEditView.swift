// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import GpgTapNotifierUserDefaults

struct ReminderTextEditView: View {
    @AppStorage(AppUserDefaults.reminderTitle.key, store: AppUserDefaults.suite)
    var reminderTitle = AppUserDefaults.reminderTitle.getDefault()

    @AppStorage(AppUserDefaults.reminderBody.key, store: AppUserDefaults.suite)
    var reminderBody = AppUserDefaults.reminderBody.getDefault()

    @AppStorage(AppUserDefaults.reminderTimeout.key, store: AppUserDefaults.suite)
    var reminderTimeout = AppUserDefaults.reminderTimeout.getDefault()

    // TODO: Pull from a static list of quotes.
    // TODO: Add a setting to make this random each time.
    static let sampleReminders = [
        (AppUserDefaults.reminderTitle.getDefault(), AppUserDefaults.reminderBody.getDefault()),
        // From: https://www.hackingwithswift.com/example-code/system/how-to-set-local-alerts-using-unnotificationcenter
        ("Late wake up call", "The early bird catches the worm, but the second mouse gets the cheese."),
    ]

    var body: some View {
        VStack {
            HStack {
                VStack {
                    TextField("Title", text: $reminderTitle).font(.body)
                    TextEditor(text: $reminderBody)
                        .font(.body)
                        .frame(height: 50)
                }
            }

            Slider(value: $reminderTimeout, in: 0.5...10, step: 0.5) {
                Text("Reminder Timeout: \(reminderTimeout, specifier: "%.1f")s")
                    .padding(.trailing)
                    .fixedSize()
            } minimumValueLabel: {
                Text("0.5s")
            } maximumValueLabel: {
                Text("10s")
            }

            HStack {
                Button("Randomize") {
                    let nextMessage = Self.sampleReminders.randomElement()!
                    self.reminderTitle = nextMessage.0
                    self.reminderBody = nextMessage.1
                }
                Button("Reset") {
                    self.reminderTitle = AppUserDefaults.reminderTitle.getDefault()
                    self.reminderBody = AppUserDefaults.reminderBody.getDefault()
                }
                Spacer()
            }
            .padding(.top)
        }
        .padding(.all)
        .frame(width: 425)
    }
}

struct ReminderTextEditView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderTextEditView()
    }
}
