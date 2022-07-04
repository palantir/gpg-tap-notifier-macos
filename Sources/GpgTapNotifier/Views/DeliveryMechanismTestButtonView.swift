// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI

struct DeliveryMechanismTestButtonView: View {
    @StateObject var agentRunner = AgentTestNotificationViewModel()
    @State private var isErrorPopoverShown = false

    var body: some View {
        HStack {
            Button(action: { isErrorPopoverShown = true }) {
                Image(systemName: "exclamationmark.circle")
            }
            .disabled(agentRunner.lastError == nil)
            .opacity(agentRunner.lastError == nil ? 0 : 1)
            .buttonStyle(.plain)
            .foregroundColor(.red)
            .popover(isPresented: $isErrorPopoverShown) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("The last notification test failed")
                    Text(agentRunner.lastError.map { $0.localizedDescription } ?? "")
                        .font(.caption)
                }
                .padding(10)
                .frame(width: 250)
            }

            Button(action: agentRunner.test) {
                Text("Test Notification")
            }
            .disabled(agentRunner.isRunning)
        }
    }
}

struct DeliveryMechanismTestView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryMechanismTestButtonView()
    }
}
