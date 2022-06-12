// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import AppKit
import Foundation

class DeliveryMechanismAlert {
    private lazy var alertWindow: NSPanel = {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)

        panel.isFloatingPanel = true

        return panel
    }()

    private var currentAlert: NSAlert?
}

extension DeliveryMechanismAlert: DeliveryMechanism {
    func present(title: String, body: String) {
        guard self.currentAlert == nil else {
            return
        }

        let alert = NSAlert()

        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational

        // NOTE: According to AppKit docs, the order buttons are added affect
        // what code they're assigned in the modalResponse.
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Open Configuration")

        self.currentAlert = alert

        // During testing the invisible alert window somehow moved to the bottom
        // left between reminders. Always center this window before we show the
        // alert as a workaround.
        alertWindow.center()

        alert.beginSheetModal(for: alertWindow) { modalResponse in
            self.currentAlert = nil

            // Corresponds with the "Open Configuration" button since it was
            // added second. What a strange API.
            if modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn {
                openConfigurationApp()
            }
        }
    }

    func dismiss() {
        guard let alert = currentAlert else {
            return
        }
        self.currentAlert = nil
        alertWindow.endSheet(alert.window)
    }
}
