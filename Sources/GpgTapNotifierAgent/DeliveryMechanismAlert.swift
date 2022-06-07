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

        panel.center()
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

        alert.addButton(withTitle: "Close")

        self.currentAlert = alert

        alert.beginSheetModal(for: alertWindow) { _ in
            self.currentAlert = nil
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
