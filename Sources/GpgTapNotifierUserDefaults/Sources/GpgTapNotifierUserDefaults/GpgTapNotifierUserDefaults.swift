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

    public static let reminderDeliveryMechanism = UserDefaultsConfig(
        key: "reminderDeliveryMechanism",
        getDefault: { ReminderDeliveryMechanismOption.alert })

    public static let reminderTimeout = UserDefaultsConfig(
        key: "notificationTimeoutSecs",
        getDefault: { 0.5 })

    public static let reminderTitle = UserDefaultsConfig(
        key: "notificationTitle",
        getDefault: { "YubiKey Awaiting Tap" })

    public static let reminderBody = UserDefaultsConfig(
        key: "notificationBody",
        getDefault: { "A GPG signature has been requested. If you initiated this action, tap your YubiKey's metal contact to confirm." })

    public static let automaticallyRestartGpgAgent = UserDefaultsConfig(
        key: "automaticallyRestartGpgAgent",
        getDefault: { true })

    public static let customHelpMessage = UserDefaultsConfig<String?>(
        key: "customHelpMessage",
        getDefault: { nil })

    public static let didEnableCommandCompletePreviously = UserDefaultsConfig(
        key: "didEnableCommandPreviouslyComplete",
        getDefault: { false }
    )
}
