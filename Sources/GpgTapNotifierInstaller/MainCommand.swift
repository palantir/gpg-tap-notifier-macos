// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation
import ArgumentParser
import GpgTapNotifierConfigLib
import GpgTapNotifierUserDefaults

let AGENT_INNER_PATH = "Contents/Library/GPG Tap Notifier Agent.app/Contents/MacOS/GPG Tap Notifier Agent"

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [
        EnableCommand.self,
        DisableCommand.self,
        SetCustomHelpMessageCommand.self,
        UnsetCustomHelpMessageCommand.self
    ])
}

struct EnableCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "enable")

    @Flag(help: "Do not perform any actions if this command has already ran. This avoids re-enabling the app on upgrades if users have opened the GUI and disabled it.")
    var noRepeatInstall = false

    func run() async throws {
        let didEnableCommandCompletePreviously = AppUserDefaults.suite?.bool(forKey: AppUserDefaults.didEnableCommandCompletePreviously.key)
            ?? AppUserDefaults.didEnableCommandCompletePreviously.getDefault()
        if (didEnableCommandCompletePreviously && noRepeatInstall) {
            print("Exiting with no modifications. This command has already ran successfully in the past.")
            return
        }

        let topLevelAppDir = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let agentBinPath = topLevelAppDir.appendingPathComponent(AGENT_INNER_PATH)

        if (!FileManager.default.fileExists(atPath: agentBinPath.path)) {
            throw EnableCommandError.missingAgentBin(agentBinPath.path)
        }

        let conf = try await loadConfigModelFromUserDefaults()
        let next = conf.insertProxyConfig(agentBinPath: agentBinPath)
        try next.writeToDisk()

        AppUserDefaults.suite?.set(true, forKey: AppUserDefaults.didEnableCommandCompletePreviously.key)
    }
}

struct DisableCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(commandName: "disable")

    func run() async throws {
        let conf = try await loadConfigModelFromUserDefaults()
        let next = conf.removeProxyConfig()
        try next.writeToDisk()
    }
}

enum EnableCommandError: Error {
    case missingAgentBin(_ agentBinPath: String)
}

extension EnableCommandError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .missingAgentBin(let agentBinPath):
            return "Unable to find agent bin at: \(agentBinPath)"
        }
    }
}

func loadConfigModelFromUserDefaults() async throws -> GpgAgentConfModel {
    let gpgAgentConfPath = AppUserDefaults.suite?.url(forKey: AppUserDefaults.gpgAgentConfPath.key)
        ?? AppUserDefaults.gpgAgentConfPath.getDefault()
    return try await GpgAgentConfModel.load(gpgAgentConfPath)
}
