// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import XCTest
@testable import GpgTapNotifierConfigLib

let AGENT_BIN_PATH: URL = URL.init(fileURLWithPath: "/test/agent/path")

class GpgAgentConfModelTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInsertProxyConfig() throws {
        let before = """
        log-file /usr/local/var/log/gpg-agent.conf
        scdaemon-program /existing/scdaemon

        """

        let expected = """
        log-file /usr/local/var/log/gpg-agent.conf
        scdaemon-program /existing/scdaemon
        # --- Start of GPG Tap Notifier Modifications ---
        \(APP_EDIT_DESCRIPTION_COMMENT)
        scdaemon-program \(AGENT_BIN_PATH.path)
        # --- End of GPG Tap Notifier Modifications ---

        """

        let model = GpgAgentConfModel(configurationFilePath: URL(fileURLWithPath: "/test/test.conf"), contents: before)
        let actual = model.insertProxyConfig(agentBinPath: AGENT_BIN_PATH).contents

        XCTAssertEqual(actual, expected)
    }

    func testInsertProxyConfigOutdatedValue() {
        let before = """
        # --- Start of GPG Tap Notifier Modifications ---
        \(APP_EDIT_DESCRIPTION_COMMENT)
        scdaemon-program /outdated/value
        # --- End of GPG Tap Notifier Modifications ---

        """

        let expected = """
        # --- Start of GPG Tap Notifier Modifications ---
        \(APP_EDIT_DESCRIPTION_COMMENT)
        scdaemon-program \(AGENT_BIN_PATH.path)
        # --- End of GPG Tap Notifier Modifications ---

        """

        let model = GpgAgentConfModel(configurationFilePath: URL(fileURLWithPath: "/test/test.conf"), contents: before)
        let actual = model.insertProxyConfig(agentBinPath: AGENT_BIN_PATH).contents

        XCTAssertEqual(actual, expected)
    }

    func testInsertProxyConfigAfterEdits() {
        let before = """
        log-file /usr/local/var/log/gpg-agent.conf
        # --- Start of GPG Tap Notifier Modifications ---
        \(APP_EDIT_DESCRIPTION_COMMENT)
        scdaemon-program \(AGENT_BIN_PATH.path)
        # --- End of GPG Tap Notifier Modifications ---

        scdaemon-program /new/value/taking/effect

        """

        let expected = """
        log-file /usr/local/var/log/gpg-agent.conf

        scdaemon-program /new/value/taking/effect
        # --- Start of GPG Tap Notifier Modifications ---
        \(APP_EDIT_DESCRIPTION_COMMENT)
        scdaemon-program \(AGENT_BIN_PATH.path)
        # --- End of GPG Tap Notifier Modifications ---

        """

        let model = GpgAgentConfModel(configurationFilePath: URL(fileURLWithPath: "/test/test.conf"), contents: before)
        let actual = model.insertProxyConfig(agentBinPath: AGENT_BIN_PATH).contents

        XCTAssertEqual(actual, expected)
    }

    func testInsertConfigProxyIdempotency() {
        let before = """
        log-file /usr/local/var/log/gpg-agent.conf
        scdaemon-program /existing/scdaemon

        """

        let expected = """
        log-file /usr/local/var/log/gpg-agent.conf
        scdaemon-program /existing/scdaemon
        # --- Start of GPG Tap Notifier Modifications ---
        \(APP_EDIT_DESCRIPTION_COMMENT)
        scdaemon-program \(AGENT_BIN_PATH.path)
        # --- End of GPG Tap Notifier Modifications ---

        """

        var model = GpgAgentConfModel(configurationFilePath: URL(fileURLWithPath: "/test/test.conf"), contents: before)

        for _ in 0..<3 {
            model = model.insertProxyConfig(agentBinPath: AGENT_BIN_PATH)
        }

        let actual = model.contents

        XCTAssertEqual(actual, expected)
    }

    func testInsertProxyConfigReplacesPreviousMarkers() {
        let before = """
        # --- Start of ScdaemonProxy Modifications ---
        \(APP_EDIT_DESCRIPTION_COMMENT)
        scdaemon-program /outdated/value
        # --- End of ScdaemonProxy Modifications ---

        """

        let expected = """
        # --- Start of GPG Tap Notifier Modifications ---
        \(APP_EDIT_DESCRIPTION_COMMENT)
        scdaemon-program \(AGENT_BIN_PATH.path)
        # --- End of GPG Tap Notifier Modifications ---

        """

        let model = GpgAgentConfModel(configurationFilePath: URL(fileURLWithPath: "/test/test.conf"), contents: before)
        let actual = model.insertProxyConfig(agentBinPath: AGENT_BIN_PATH).contents

        XCTAssertEqual(actual, expected)
    }

    func testConfigRemoval() {
        let before = """
        log-file /usr/local/var/log/gpg-agent.conf
        scdaemon-program /test/scdaemon-program

        """

        var model = GpgAgentConfModel(configurationFilePath: URL(fileURLWithPath: "/test/test.conf"), contents: before)

        for _ in 0..<3 {
            model = model.insertProxyConfig(agentBinPath: AGENT_BIN_PATH)
            model = model.removeProxyConfig()
        }

        let actual = model.contents

        XCTAssertEqual(actual, before)
    }
}
