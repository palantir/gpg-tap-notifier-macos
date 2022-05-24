// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

enum RunProcessError: Error {
    case execError(Error)
    case nonZeroExit(Int32)
}

/// Wraps Process.run to make it an async function. Standard out and error are not captured.
func run(_ url: URL, arguments: [String]) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(), Error>) in
        do {
            try Process.run(url, arguments: arguments) { task in
                if task.terminationStatus == 0 {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: RunProcessError.nonZeroExit(task.terminationStatus))
                }
            }
        } catch {
            continuation.resume(throwing: RunProcessError.execError(error))
        }
    }
}
