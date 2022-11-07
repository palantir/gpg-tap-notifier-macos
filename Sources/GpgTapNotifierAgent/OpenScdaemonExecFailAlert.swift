// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import AppKit
import Foundation

func openScdaemonExecFailAlert(scdaemonPath: URL, error: Error) {
    let alert = NSAlert()

    alert.alertStyle = .critical
    alert.messageText = "Failed to start scdaemon"
    alert.informativeText = """
    Error: \(error.localizedDescription)

    We recommend opening the configuration app and checking that the chosen scdaemon path is valid.

    Current path: \(scdaemonPath.path)
    """

    // NOTE: According to AppKit docs, the order buttons are added affect
    // what code they're assigned in the modalResponse.
    alert.addButton(withTitle: "Open Configuration")
    alert.addButton(withTitle: "Cancel")

    // The main.swift file sets ActivationPolicy.prohibited to prevent the
    // daemon from showing in the macOS dock. When there's a critical error, it
    // may be more helpful to show a dock icon to associate the alert with.
    NSApplication.shared.setActivationPolicy(.regular)

    alert.window.center()

    // The .runModal() method runs synchronously and all event processing is
    // blocked. This is normally a problem, but fine when showing a critical
    // alert immediately before application exit.
    let modalResponse = alert.runModal()

    if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
        openConfigurationApp()
    }
}
