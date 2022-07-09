// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation
import GpgTapNotifierConfigLib

class GpgAgentConfViewModel: NSObject, ObservableObject {
    @Published private(set) var state: GpgAgentConfAsync = .loading

    // Fields to satisfy NSFilePresenter protocol conformance.
    var presentedItemURL: URL?
    var presentedItemOperationQueue: OperationQueue = OperationQueue.main

    var isProxyInstalled: Bool {
        switch self.state {
        case .loading, .missing, .failed: return false
        case .loaded(let value), .reloading(let value): return value.scdaemonProgramValue == AGENT_BIN_PATH.path
        }
    }

    @MainActor
    func toggle(_ isEnabled: Bool) throws {
        guard case let GpgAgentConfAsync.loaded(loaded) = self.state else {
            return
        }

        let next = isEnabled
            ? loaded.insertProxyConfig(agentBinPath: AGENT_BIN_PATH)
            : loaded.removeProxyConfig()
        try next.writeToDisk()

        state = .loaded(next)
    }

    @MainActor
    func reload(_ url: URL) async {
        switch self.state {
        case .failed, .loading, .missing:
            self.state = .loading
        case .reloading(let previous), .loaded(let previous):
            self.state = .reloading(previous)
        }

        if let presentedItemURL = self.presentedItemURL, presentedItemURL != url {
            // Removing the file presenter before updating self.presentedItemURL
            // below. This is required to make the presenter watch the file at
            // the new path.
            NSFileCoordinator.removeFilePresenter(self)
            self.presentedItemURL = nil
        }

        if self.presentedItemURL == nil {
            self.presentedItemURL = url
            NSFileCoordinator.addFilePresenter(self)
        }

        self.state = await GpgAgentConfAsync.load(url)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }
}

extension GpgAgentConfViewModel: NSFilePresenter {
    func presentedItemDidChange() {
        // It'd be unexpected for this callback to fire while
        // self.presentedItemURL is empty, but probably okay to fail gracefully
        // on that instead of fatally exiting.
        guard let presentedItemURL = self.presentedItemURL else {
            return
        }

        Task {
            await self.reload(presentedItemURL)
        }
    }
}

enum GpgAgentConfAsync {
    case loading
    case missing
    case failed(Error)
    case reloading(GpgAgentConfModel)
    case loaded(GpgAgentConfModel)

    static func load(_ url: URL) async -> GpgAgentConfAsync {
        do {
            let loaded = try await GpgAgentConfModel.load(url)
            return GpgAgentConfAsync.loaded(loaded)
        } catch {
            return GpgAgentConfAsync.failed(error)
        }
    }
}
