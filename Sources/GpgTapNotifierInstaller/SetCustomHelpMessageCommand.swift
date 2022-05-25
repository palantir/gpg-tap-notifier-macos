// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation
import ArgumentParser
import GpgTapNotifierUserDefaults

struct SetCustomHelpMessageCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "set-custom-help-message")

    @Argument(help: "A custom message shown in the configurational user interface.")
    var message: String

    func run() throws {
        guard let suite = AppUserDefaults.suite else {
            throw SetCustomHelpMessageCommandError.missingSuite
        }

        suite.set(message, forKey: AppUserDefaults.customHelpMessage.key)
    }
}

enum SetCustomHelpMessageCommandError: Error {
    case missingSuite
}

extension SetCustomHelpMessageCommandError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingSuite: return "Unable to find UserDefaults suite."
        }
    }
}
