// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import UniformTypeIdentifiers

struct FilePathItemView: View {
    @Binding var path: URL
    var allowedContentTypes: [UTType]
    var name: String
    var icon: Image

    var body: some View {
        HStack(alignment: .center) {
            icon.imageScale(.large)
                .frame(width: 20)
                .foregroundColor(Color.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                Text(path.path).font(.footnote)
            }
            Spacer()
            Button("Select...") {
                self.selectPath()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    func selectPath() {
        let openPanel = NSOpenPanel()

        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = self.allowedContentTypes
        openPanel.showsHiddenFiles = true
        openPanel.directoryURL = NSURL.fileURL(withPath: path.deletingLastPathComponent().path)

        let response = openPanel.runModal()

        // TODO: Is it possible for openPanel.url to be nil after the response is .OK?
        if response == .OK, let selectedUrl = openPanel.url {
            self.path = selectedUrl
        }
    }
}
