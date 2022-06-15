// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import GpgTapNotifierUserDefaults

struct NotificationMessageEditView: View {
    @AppStorage(AppUserDefaults.notificationTitle.key, store: AppUserDefaults.suite)
    var notificationTitle = AppUserDefaults.notificationTitle.getDefault()

    @AppStorage(AppUserDefaults.notificationBody.key, store: AppUserDefaults.suite)
    var notificationBody = AppUserDefaults.notificationBody.getDefault()

    @AppStorage(AppUserDefaults.notificationTimeoutSecs.key, store: AppUserDefaults.suite)
    var notificationTimeout = AppUserDefaults.notificationTimeoutSecs.getDefault()

    // TODO: Pull from a static list of quotes.
    // TODO: Add a setting to make this random each time.
    static let sampleReminders = [
        (AppUserDefaults.notificationTitle.getDefault(), AppUserDefaults.notificationBody.getDefault()),
        // From: https://www.hackingwithswift.com/example-code/system/how-to-set-local-alerts-using-unnotificationcenter
        ("Late wake up call", "The early bird catches the worm, but the second mouse gets the cheese."),
    ]

    var body: some View {
        VStack {
            HStack {
                VStack {
                    TextField("Title", text: $notificationTitle).font(.body)
                    TextEditor(text: $notificationBody)
                        .font(.body)
                        .frame(height: 50)
                }
            }

            Slider(value: $notificationTimeout, in: 1...10, step: 1.0) {
                Text("Notification Timeout (s)")
                    .padding(.trailing)
            } minimumValueLabel: {
                Text("1s")
            } maximumValueLabel: {
                Text("10s")
            }

            HStack {
                Button("Randomize") {
                    let nextMessage = Self.sampleReminders.randomElement()!
                    self.notificationTitle = nextMessage.0
                    self.notificationBody = nextMessage.1
                }
                Button("Reset") {
                    self.notificationTitle = AppUserDefaults.notificationTitle.getDefault()
                    self.notificationBody = AppUserDefaults.notificationBody.getDefault()
                }
                Spacer()
            }
            .padding(.top)
        }
        .padding(.all)
        .frame(width: 400)
    }
}

struct NotificationMessageEditView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationMessageEditView()
    }
}
