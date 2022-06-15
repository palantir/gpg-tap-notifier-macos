// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import GpgTapNotifierUserDefaults

struct ContentView: View {
    @AppStorage(AppUserDefaults.gpgAgentConfPath.key, store: AppUserDefaults.suite)
    private var gpgAgentConfPath: URL = AppUserDefaults.gpgAgentConfPath.getDefault()
    @AppStorage(AppUserDefaults.gpgconfPath.key, store: AppUserDefaults.suite)
    var gpgconfPath: URL = URL(fileURLWithPath:  AppUserDefaults.gpgconfPath.getDefault())
    @AppStorage(AppUserDefaults.scdaemonPath.key, store: AppUserDefaults.suite)
    var scdaemonPath: URL = URL(fileURLWithPath: AppUserDefaults.scdaemonPath.getDefault())
    @AppStorage(AppUserDefaults.customHelpMessage.key, store: AppUserDefaults.suite)
    private var customHelpMessage: String?

    @State private var showingNotificationMessageEditSheet = false
    
    var customHelpMessageText: Text {
        if #available(macOS 12, *) {
            return Text(try! AttributedString(markdown: .init(customHelpMessage ?? "")))
        } else {
            return Text(customHelpMessage ?? "")
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to GPG Tap Notifier")
                .font(.title)
                .fixedSize()
            Text("This application provides reminders to tap your security device (e.g. YubiKey) by wrapping communication between gpg-agent and scdaemon. This mechanism works well in most cases, but you may see false positives from time to time.")
                .font(.body)
                .lineLimit(4)
                .padding(.vertical)
                .fixedSize(horizontal: false, vertical: true)

            customHelpMessageText
                .font(.body)
                .lineLimit(3)
                .padding(customHelpMessage != nil ? [.bottom] : [])
                .opacity(customHelpMessage != nil ? 1 : 0)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            GpgAgentConfSectionView(
                gpgAgentConfPath: $gpgAgentConfPath,
                gpgconfPath: $gpgconfPath,
                scdaemonPath: self.scdaemonPath)
                .padding(.vertical)

            TabView {
                VStack {
                    DeliveryMechanismChooserView()
                        .padding()
                    Spacer()
                }
                .tabItem { Text("Delivery") }

                VStack {
                    FilePathsView(
                        gpgAgentConfPath: $gpgAgentConfPath,
                        gpgconfPath: $gpgconfPath,
                        scdaemonPath: $scdaemonPath)
                    Spacer()
                }
                .tabItem { Text("File Paths") }

                VStack {
                    NotificationMessageEditView()
                    Spacer()
                }
                .tabItem { Text("Message Text") }
            }
        }.padding(40)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
