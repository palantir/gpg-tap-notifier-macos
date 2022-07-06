// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

class AgentTestNotificationViewModel: ObservableObject {
    @Published var state: TestState = .idle

    enum TestState {
        case idle
        case running(Task<(), Never>)
        case errored(Error)
    }

    var isRunning: Bool {
        switch state {
        case .running(_): return true
        default: return false
        }
    }

    var lastError: Error? {
        switch state {
        case .idle, .running(_): return nil
        case .errored(let err): return err
        }
    }

    @MainActor
    func test() {
        switch state {
        case .running(_): return
        case .idle, .errored(_): break
        }

        let runTask = Task {
            do {
                try await testNotification()
                state = .idle
            } catch {
                state = .errored(error)
            }
        }

        state = .running(runTask)
    }

    func cancel() {
        switch state {
        case .idle, .errored(_): break
        case .running(let runTask): runTask.cancel()
        }
    }
}

func testNotification() async throws {
    try await run(AGENT_BIN_PATH, arguments: ["--gpg-tap-notifier-test-notification"])
}
