// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI

struct DeliveryMechanismTestButtonView: View {
    @State private var isTestingNotification = false

    @State private var isErrorPopoverShown = false
    @State private var lastError: Error?

    var body: some View {
        HStack {
            Button(action: { isErrorPopoverShown = true }) {
                Image(systemName: "exclamationmark.circle")
            }
            .disabled(lastError == nil)
            .opacity(lastError == nil ? 0 : 1)
            .buttonStyle(.plain)
            .foregroundColor(.red)
            .popover(isPresented: $isErrorPopoverShown) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("The last notification test failed")
                    Text(lastError.map { $0.localizedDescription } ?? "")
                        .font(.caption)
                }
                .padding(10)
                .frame(width: 250)
            }

            Button(action: onClick) {
                Text("Test Notification")
            }
            .disabled(isTestingNotification)
        }
    }

    func onClick() {
        Task {
            self.isTestingNotification = true
            self.lastError = nil
            defer { self.isTestingNotification = false }

            do {
                try await testNotification()
            } catch {
                self.lastError = error
            }
        }
    }
}

struct DeliveryMechanismTestView_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryMechanismTestButtonView()
    }
}

func testNotification() async throws {
    try await run(AGENT_BIN_PATH, arguments: ["--gpg-tap-notifier-test-notification"])
}
