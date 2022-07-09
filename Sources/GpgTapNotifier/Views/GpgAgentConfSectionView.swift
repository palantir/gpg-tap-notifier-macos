// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import SwiftUI
import GpgTapNotifierUserDefaults

enum GpgAgentConfState {
    case fileNotSelected
    case fileNotReadable
    case fileLoading
    case proxyIsNotInstalled
    case proxyIsInstalled
}

struct GpgAgentConfSectionView: View {
    @Binding var gpgAgentConfPath: URL
    @Binding var gpgconfPath: URL
    var scdaemonPath: URL

    @AppStorage(AppUserDefaults.automaticallyRestartGpgAgent.key, store: AppUserDefaults.suite)
    var automaticallyRestartGpgAgent = AppUserDefaults.automaticallyRestartGpgAgent.getDefault()

    @State private var isRestartingGpgAgent: Bool = false

    /// The current toggle value. Do not update this outside of the
    /// `syncIsEnabledToggleFromConfig` function. The sync function manages a
    /// delicate 2-way binding between the toggle UI state and the config. It
    /// properly sets the `isNextEnabledToggleUpdateBackgroundRefresh` value.
    ///
    /// 2-way binding is a known difficult coding pattern. Ideally the toggle
    /// value here is a 1-way binding with the config being the source of truth,
    /// but the SwiftUI `Switch` view does not have a "controlled" mode, to use
    /// React.js parlance.
    @State private var isEnabledToggleValue: Bool = false
    /// This stateful value is a workaround for the inability to distinguish
    /// between human interaction of a SwiftUI switch and background updates to
    /// the keep its value up to date. Only the former (human interaction)
    /// should trigger gpg-agent restart logic.
    @State private var isNextEnabledToggleUpdateBackgroundRefresh: Bool = false

    @StateObject var conf: GpgAgentConfViewModel = GpgAgentConfViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                HStack(alignment: .center) {
                    Circle()
                        .size(width: 10, height: 10)
                        .fill(self.getStatusColor())
                        .frame(width: 10, height: 10)
                    Text("GPG Agent Configuration: \(self.getStatusText())").bold()
                    ProgressViewLoadingGpgConf(isSpinnerShown: isSpinnerShown)
                }
                .fixedSize()

                Spacer()

                Toggle("Enabled", isOn: self.$isEnabledToggleValue)
                    .toggleStyle(.switch)
                    .fixedSize()
                    .disabled(self.isRestartingGpgAgent || self.isNextEnabledToggleUpdateBackgroundRefresh)
                    .onChange(of: self.isEnabledToggleValue) { nextIsEnabled in
                        Task {
                            try await onToggleChange(nextIsEnabled)
                        }
                    }
            }

            Text(self.statusDescription ?? "")
                .font(.callout)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .frame(height: 50, alignment: .top)

            Toggle(isOn: $automaticallyRestartGpgAgent) {
                Text("Restart gpg-agent when enabling or disabling")
            }
            .padding(.top)
            .fixedSize()
        }
        .onAppear {
            // Refactor this to .task from .onAppear when macOS 11.x support
            // can be dropped.
            Task {
                await self.conf.reload(self.gpgAgentConfPath)
                self.syncIsEnabledToggleFromConfig()
            }
        }
        .onChange(of: self.gpgAgentConfPath) { gpgAgentConfPath in
            Task {
                await self.conf.reload(gpgAgentConfPath)
            }
        }
        .onChange(of: self.conf.isProxyInstalled) { _ in
            self.syncIsEnabledToggleFromConfig()
        }
    }

    func getStatusText() -> String {
        switch self.conf.state {
        case .loading: return "Loading..."
        case .missing: return "File Not Found"
        case .failed: return "Failed to Read"
        case .loaded(_), .reloading(_): return self.conf.isProxyInstalled
            ? "Proxy Configured"
            : "Proxy Disabled"
        }
    }

    func getStatusColor() -> Color {
        if self.isRestartingGpgAgent {
            return Color.gray
        }

        switch self.conf.state {
        case .loading: return Color.gray
        case .missing: return Color.yellow
        case .failed: return Color.red
        case .loaded(_), .reloading(_): return self.conf.isProxyInstalled
            ? Color.green
            : Color.orange
        }
    }

    var statusDescription: String? {
        if self.isRestartingGpgAgent {
            return nil
        }

        switch self.conf.state {
        case .loading:
            return nil
        case .missing:
            return "The gpg-agent.conf file wasn't found at the path selected below."
        case .failed(let error):
            return "Failed to read gpg-agent.conf at the path selected below. \(error.localizedDescription)"
        case .loaded(_), .reloading(_):
            return self.conf.isProxyInstalled
                ? "The proxy is enabled. This app can be safely closed."
                : "Click the Enable button to edit gpg-agent.conf and restart gpg-agent. Otherwise you may safely delete this .app if you no longer wish to receive tap reminders."
        }
    }

    var isToggleDisabled: Bool {
        switch self.conf.state {
        case .loaded(_): return false
        default: return true
        }
    }

    var isSpinnerShown: Bool {
        if self.isRestartingGpgAgent {
            return true
        }

        switch self.conf.state {
        case .loading, .reloading(_): return true
        case .missing, .failed, .loaded(_): return false
        }
    }

    func syncIsEnabledToggleFromConfig() {
        if self.isEnabledToggleValue != self.conf.isProxyInstalled {
            self.isNextEnabledToggleUpdateBackgroundRefresh = true
        }

        self.isEnabledToggleValue = self.conf.isProxyInstalled
    }

    @MainActor
    func onToggleChange(_ nextIsEnabled: Bool) async throws {
        if self.isNextEnabledToggleUpdateBackgroundRefresh {
            // The Switch was toggled, but only from due to the config changing
            // on disk outside of this application. In that case there's no need
            // to edit the config or restart gpg-agent. (Actually a gpg-agent
            // restart may be required, but that's a complex condition to
            // check.)
            self.isNextEnabledToggleUpdateBackgroundRefresh = false
            return
        }

        try self.conf.toggle(nextIsEnabled)

        guard self.automaticallyRestartGpgAgent else {
            return
        }

        self.isRestartingGpgAgent = true
        defer {
            self.isRestartingGpgAgent = false
        }

        // TODO: Catch errors here and signal them to users.

        // The --reload flag doesn't seem to make gpg-agent pick up scdaemon-program
        // conf changes. Running --kill and --launch in sequence instead.
        try await run(self.gpgconfPath, arguments: ["--kill", "gpg-agent"])
        try await run(self.gpgconfPath, arguments: ["--launch", "gpg-agent"])
    }
}

struct GpgAgentConfSectionView_Previews: PreviewProvider {
    static var previews: some View {
        GpgAgentConfSectionView(
            gpgAgentConfPath: .constant(AppUserDefaults.gpgAgentConfPath.getDefault()),
            gpgconfPath: .constant(URL(fileURLWithPath: AppUserDefaults.gpgconfPath.getDefault())),
            scdaemonPath: URL(fileURLWithPath: AppUserDefaults.scdaemonPath.getDefault()))
    }
}
