// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation
import ArgumentParser
import GpgTapNotifierUserDefaults

struct UnsetCustomHelpMessageCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "unset-custom-help-message")

    func run() throws {
        guard let suite = AppUserDefaults.suite else {
            throw UnsetCustomHelpMessageCommandError.missingSuite
        }

        suite.removeObject(forKey: AppUserDefaults.customHelpMessage.key)
    }
}

enum UnsetCustomHelpMessageCommandError: Error {
    case missingSuite
}

extension UnsetCustomHelpMessageCommandError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingSuite: return "Unable to find UserDefaults suite."
        }
    }
}
