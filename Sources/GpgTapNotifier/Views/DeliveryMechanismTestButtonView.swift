// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI

struct DeliveryMechanismTestButtonView: View {
    @StateObject var agentRunner = AgentTestNotificationViewModel()
    @State private var isErrorPopoverShown = false

    var body: some View {
        HStack {
            if let lastError = agentRunner.lastError {
                Button(action: { isErrorPopoverShown = true }) {
                    Image(systemName: "exclamationmark.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .onHover { isErrorPopoverShown = $0 }
                .popover(isPresented: $isErrorPopoverShown) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("The last notification test failed")
                        Text(lastError.localizedDescription)
                            .font(.caption)
                    }
                    .padding(10)
                    .frame(minWidth: 200, maxWidth: 250)
                }
            }

            if (agentRunner.isRunning) {
                Button(action: agentRunner.cancel) {
                    Image(systemName: "x.circle")
                }
                .buttonStyle(.plain)
            }

            Button(action: { agentRunner.test() }) {
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
