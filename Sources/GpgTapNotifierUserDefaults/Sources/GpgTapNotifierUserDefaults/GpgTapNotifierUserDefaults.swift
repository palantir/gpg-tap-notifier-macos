// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

public struct AppUserDefaults  {
    // The namespace for UserDefaults configuration shared between the configuration
    // GUI and Agent. This should match the "App Groups" capability defined in the
    // .xcodeproj metadata file.
    public static let SUITE_NAME = "PXSBYN8444.com.palantir.gpg-tap-notifier"
    public static let suite = UserDefaults(suiteName: "PXSBYN8444.com.palantir.gpg-tap-notifier")

    public static let gpgAgentConfPath = UserDefaultsConfig(
        key: "gpgAgentConfPath",
        getDefault: { () -> URL in
            // This should be the directory scdaemon resides in for users of gpgtools.org.
            let gpgAgentConfLikelyDir = ".gnupg"
            let gpgAgentConfLikelyFilename = "gpg-agent.conf"

            return FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent(gpgAgentConfLikelyDir)
                .appendingPathComponent(gpgAgentConfLikelyFilename)
        })

    public static let scdaemonPath = UserDefaultsConfig(
        key: "scdaemonPath",
        getDefault: { "/usr/local/MacGPG2/libexec/scdaemon" })

    public static let gpgconfPath = UserDefaultsConfig(
        key: "gpgconfPath",
        getDefault: { "/usr/local/MacGPG2/bin/gpgconf" })

    public static let notificationTimeoutSecs = UserDefaultsConfig(
        key: "notificationTimeoutSecs",
        getDefault: { 1.0 })

    public static let notificationTitle = UserDefaultsConfig(
        key: "notificationTitle",
        getDefault: { "YubiKey Reminder" })

    public static let notificationBody = UserDefaultsConfig(
        key: "notificationBody",
        getDefault: { "Is your YubiKey blinking? You may need to touch its metal contact." })

    public static let automaticallyRestartGpgAgent = UserDefaultsConfig(
        key: "automaticallyRestartGpgAgent",
        getDefault: { true })

    public static let customHelpMessage = UserDefaultsConfig<String?>(
        key: "customHelpMessage",
        getDefault: { nil })
}
