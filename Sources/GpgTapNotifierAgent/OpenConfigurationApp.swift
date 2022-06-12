// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import AppKit

import Foundation
func openConfigurationApp() {
    guard let configurationAppUrl = guessConfigurationAppUrl() else {
        return
    }
    NSWorkspace.shared.open(configurationAppUrl)
}

func guessConfigurationAppUrl() -> URL? {
    let agentBundleUrl = Bundle.main.bundleURL

    // The agent bundle lives within "Contents/Library/GPG Tap Notifier Agent.app". Trim these paths.
    let mainAppUrl = agentBundleUrl.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    if mainAppUrl.path.hasSuffix(".app") {
        return mainAppUrl
    }

    // The Agent app may not be inside the normal GUI app's Contents/Library dir during development.
    // Guessing from the GUI app's bundle identifier as the next
    return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.palantir.gpg-tap-notifier")
}
