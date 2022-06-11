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
        VStack {
            Picker("Delivery Mechanism", selection: $reminderDeliveryMechanism) {
                ForEach(ReminderDeliveryMechanismOption.allCases) { Text($0.description) }
            }.pickerStyle(.segmented)
        }
    }
}

struct DeliveryMechanismChooserView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryMechanismChooserView()
    }
}
