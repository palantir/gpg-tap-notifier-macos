// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

class AgentTestNotificationViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var lastError: Error?

    func test() {
        Task {
            self.isRunning = true
            self.lastError = nil
            defer { self.isRunning = false }

            do {
                try await testNotification()
            } catch {
                self.lastError = error
            }
        }
    }
}

func testNotification() async throws {
    try await run(AGENT_BIN_PATH, arguments: ["--gpg-tap-notifier-test-notification"])
}
