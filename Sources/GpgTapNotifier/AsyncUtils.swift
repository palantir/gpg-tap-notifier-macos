// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

enum RunProcessError: Error {
    case execError(Error)
    case nonZeroExit(Int32)
}

extension RunProcessError : LocalizedError {
    var errorDescription: String? {
        switch self {
        case .execError(let error): return "The process failed to start: \(error)"
        case .nonZeroExit(let exitCode): return "Process exited with non-zero code: \(exitCode)"
        }
    }
}

/// Wraps Process.run to make it an async function. Standard out and error are not captured.
func run(_ url: URL, arguments: [String]) async throws {
    let process = Process()
    process.executableURL = url
    process.arguments = arguments

    return try await withTaskCancellationHandler(handler: { process.interrupt() }) {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(), Error>) in
            process.terminationHandler = { task in
                if task.terminationStatus == 0 {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: RunProcessError.nonZeroExit(task.terminationStatus))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: RunProcessError.execError(error))
            }
        }
    }
}
