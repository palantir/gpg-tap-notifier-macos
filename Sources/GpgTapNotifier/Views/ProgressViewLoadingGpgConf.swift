// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI

struct ProgressViewLoadingGpgConf: View {
    var isSpinnerShown = false
    @State private var opacity: Double = 0

    var body: some View {
        ProgressView()
            .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
            .frame(width: 16, height: 16)
            .opacity(self.opacity)
            .onChange(of: self.isSpinnerShown) { nextIsShown in
                if nextIsShown {
                    self.opacity = 1
                } else {
                    // Only animate out.
                    withAnimation(.easeIn) {
                        self.opacity = 0
                    }
                }
            }
    }
}

struct ProgressViewLoadingGpgConf_Previews: PreviewProvider {
    static var previews: some View {
        ProgressViewLoadingGpgConf()
    }
}
