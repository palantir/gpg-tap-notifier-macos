// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import AppKit
import Foundation

class DeliveryMechanismAlert {
    struct PresentingState {
        let continuation: CheckedContinuation<PresentStopReason, Never>
        let currentAlertWindow: NSPanel
        let currentAlert: NSAlert
    }

    /// Non-nil if an alert is currently displayed.
    private var presentingState: PresentingState? = nil
}

extension DeliveryMechanismAlert: DeliveryMechanism {
    @MainActor
    func present(title: String, body: String) async -> PresentStopReason {
        guard presentingState == nil else {
            return .existingReminderDisplayed
        }

        let alert = NSAlert()

        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational

        // NOTE: According to AppKit docs, the order buttons are added affect
        // what code they're assigned in the modalResponse.
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Open Configuration")

        let alertWindow = NSPanel(
            // Without setting width/height to a non-zero value, the NSAlert
            // appears to always display on the primary screen instead of
            // NSScreen.main (the screen with the active window). This can be
            // jarring and causes the NSAlert animation to fly from one screen
            // to the other. The 1 x 1 px window ends up not being visible to
            // users since it's under the NSAlert.
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        alertWindow.isFloatingPanel = true
        alertWindow.center()

        return await withCheckedContinuation { (continuation: CheckedContinuation<PresentStopReason, Never>) in
            self.presentingState = PresentingState(
                continuation: continuation,
                currentAlertWindow: alertWindow,
                currentAlert: alert)

            alert.beginSheetModal(for: alertWindow) { modalResponse in
                // The beginSheetModal completionHandler callback here should
                // always run when the modal closes. If the presentingState is
                // already nil, the dismiss() method was likely just called.
                if let presentingState = self.presentingState {
                    self.presentingState = nil
                    presentingState.continuation.resume(returning: .userManuallyCleared)
                    presentingState.currentAlertWindow.close()
                }

                // Corresponds with the "Open Configuration" button since it was
                // added second. What a strange API.
                if modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn {
                    openConfigurationApp()
                }
            }
        }
    }

    func dismiss() {
        guard let presentingState = presentingState else {
            return
        }
        self.presentingState = nil

        presentingState.continuation.resume(returning: .dismissed)
        presentingState.currentAlertWindow.endSheet(presentingState.currentAlert.window)
        presentingState.currentAlertWindow.close()
    }
}
