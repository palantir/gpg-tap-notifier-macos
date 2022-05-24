// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import GpgTapNotifierUserDefaults

struct FilePathsView: View {
    @Binding var gpgAgentConfPath: URL
    @Binding var gpgconfPath: URL
    @Binding var scdaemonPath: URL

    var body: some View {
        // TODO: Switch VStack -> List and use the builtin alternating background feature the deployment target can be bumped to macoS 12.0
        VStack(alignment: .leading, spacing: 0) {
            FilePathItemView(
                path: $gpgAgentConfPath,
                allowedContentTypes: [.data],
                name: "GPG Agent Config File",
                icon: Image(systemName: "doc.circle")
            )
            .background(Color(NSColor.alternatingContentBackgroundColors[0]))

            FilePathItemView(
                path: $scdaemonPath,
                allowedContentTypes: [.unixExecutable],
                name: "Smartcard Daemon",
                icon: Image(systemName: "simcard")
            )
            .background(Color(NSColor.alternatingContentBackgroundColors[1]))

            FilePathItemView(
                path: $gpgconfPath,
                allowedContentTypes: [.unixExecutable],
                name: "GPG Config Binary",
                icon: Image(systemName: "gear")
            )
            .background(Color(NSColor.alternatingContentBackgroundColors[0]))
        }
        .border(Color(NSColor.gridColor), width: 1)
    }
}

struct FilePathsView_Previews: PreviewProvider {
    static var previews: some View {
        FilePathsView(
            gpgAgentConfPath: .constant(AppUserDefaults.gpgAgentConfPath.getDefault()),
            gpgconfPath: .constant(URL(fileURLWithPath: AppUserDefaults.gpgconfPath.getDefault())),
            scdaemonPath: .constant(URL(fileURLWithPath:  AppUserDefaults.scdaemonPath.getDefault())))
    }
}
