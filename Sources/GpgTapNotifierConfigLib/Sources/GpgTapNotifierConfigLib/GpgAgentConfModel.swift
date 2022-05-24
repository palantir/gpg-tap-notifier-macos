// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

let SCDAEMON_PROGRAM_FILENAME_REGEX = #"(^|\n)\s*scdaemon-program\s+(?<filename>.+)($|\n)"#

let APP_EDIT_MARKER = (
    start: "# --- Start of GPG Tap Notifier Modifications ---",
    end: "# --- End of GPG Tap Notifier Modifications ---\n"
)

let PREVIOUS_APP_EDIT_MARKERS = [
    (
        start: "# --- Start of ScdaemonProxy Modifications ---",
        end: "# --- End of ScdaemonProxy Modifications ---\n"
    )
]

let APP_EDIT_DESCRIPTION_COMMENT = """
# The lines in this section were automatically added by GPG Tap Notifier.app.
# Any manual edits in this section may be reset. This section can be safely
# deleted if you wish to uninstall the GPG Tap Notifier app.
"""

public struct GpgAgentConfModel {
    var configurationFilePath: URL
    var contents: String

    public func withNewContents(_ contents: String) -> Self {
        return Self(configurationFilePath: self.configurationFilePath, contents: contents)
    }

    private var scdaemonProgramConfRange: Range<String.Index>? {
        let expression = try! NSRegularExpression(pattern: SCDAEMON_PROGRAM_FILENAME_REGEX)
        let fullRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)

        let filenameRange = expression.matches(in: contents, range: fullRange)
            .last?
            .range(withName: "filename")

        return filenameRange.flatMap { Range($0, in: contents) }
    }

    public var scdaemonProgramValue: String? {
        return self.scdaemonProgramConfRange.map { String(contents[$0]) }
    }

    public func insertProxyConfig(agentBinPath: URL) -> GpgAgentConfModel {
        if self.scdaemonProgramValue == agentBinPath.path {
            return self
        }

        let edits = """
        \(APP_EDIT_MARKER.start)
        \(APP_EDIT_DESCRIPTION_COMMENT)
        scdaemon-program \(agentBinPath.path)
        \(APP_EDIT_MARKER.end)
        """

        var contents = self.contents

        // If the existing scdaemon-program config value is below our config, we have to
        // clear out the existing config block and make sure it's reinserted further down.
        // gpg-agent uses the last scdaemon-program config line.
        if let appEditsRange = Self.getAppEditsRange(contents),
           let scdaemonProgramRange = self.scdaemonProgramConfRange,
           appEditsRange.upperBound < scdaemonProgramRange.lowerBound {
            contents.removeSubrange(appEditsRange)
        }

        if let appEditsRange = Self.getAppEditsRange(contents) {
            contents.replaceSubrange(appEditsRange, with: edits)
            return self.withNewContents(contents)
        } else {
            // Intentionally leaving any original scdaemon-program config lines untouched.
            // This makes disabling easier since only our appended block has to be deleted,
            // and gpg-agent will start using the original line written earlier.
            return self.withNewContents(contents.appending(edits))
        }
    }

    public func removeProxyConfig() -> GpgAgentConfModel {
        guard let appEditsRange = Self.getAppEditsRange(self.contents) else {
            return self
        }

        var contents = self.contents
        contents.replaceSubrange(appEditsRange, with: "")
        return self.withNewContents(contents)
    }

    public func writeToDisk() throws {
        try self.contents.write(to: self.configurationFilePath, atomically: true, encoding: .utf8)
    }

    private static func getAppEditsRange(_ contents: String) -> Range<String.Index>? {
        // This application was renamed in April 2022. To allow config edits with the
        // old name to still be recognized, search any previously valid markers and
        // allow those to continue to be recognized in the same manner.
        //
        // Note that this could be O(filesize) instead of O(filesize * markers), but the
        // regex implementation seems much more complex.
        return [[APP_EDIT_MARKER], PREVIOUS_APP_EDIT_MARKERS]
            .lazy
            .joined()
            .compactMap { self.getAppEditsRange(contents, forMarkers: $0) }
            // The .first method without a closure doesn't support lazy sequences.
            .first { _ in true }
    }

    private static func getAppEditsRange(_ contents: String, forMarkers markers: (start: String, end: String)) -> Range<String.Index>? {
        let startCommentRange = contents.range(of: markers.start)
        let endCommentRange = contents.range(of: markers.end, options: .backwards)

        guard let startCommentRange = startCommentRange, let endCommentRange = endCommentRange else {
            return nil
        }

        return startCommentRange.lowerBound..<endCommentRange.upperBound
    }

    static public func load(_ configurationFilePath: URL) async throws -> GpgAgentConfModel {
        let handle = try FileHandle(forUpdating: configurationFilePath)
        let bytes = Data(referencing: try await readFile(handle))
        let contents = String(decoding: bytes, as: UTF8.self)

        return GpgAgentConfModel(configurationFilePath: configurationFilePath, contents: contents)
    }
}
