// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI

// Ideally this application picks a reasonable initial width, but still allows
// users to resize. Unfortunately there doesn't seem to be a way to do this with
// SwiftUI yet, so we'll set this to a fixed hard-coded value for now. Otherwise
// the application starts at a default of 900 points. (Not sure where 900 is
// getting picked up from.)
//
// Note that this matches the behavior of macOS System Preferences, which
// doesn't allow horizontal resizing either.
let CONTENT_VIEW_WIDTH: CGFloat = 525

@main
struct GpgTapNotifierApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: CONTENT_VIEW_WIDTH)
        }
    }
}
