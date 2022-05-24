// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

enum ReadCompletionError: Error {
    /// An NSNumber object containing an integer representing the UNIX-type error which occurred.
    /// https://developer.apple.com/documentation/foundation/filehandle/1414257-readcompletionnotification
    case code(NSNumber)

    case missing
}

extension ReadCompletionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .code(let code):
            return "Encountered error code while reading: \(code)"
        case .missing:
            return "No data or error was found in the userInfo response for this read completion."
        }
    }
}

/// Wraps FileHandle.readCompletionNotification userInfo responses around a Result type.
func readCompletionResult(_ userInfo: [AnyHashable : Any]) -> Result<NSData, ReadCompletionError> {
    if let error = userInfo["NSFileHandleError"] {
        let code = error as! NSNumber
        return .failure(ReadCompletionError.code(code))
    }

    if let data = userInfo[NSFileHandleNotificationDataItem] {
        let data = data as! NSData
        return .success(data)
    }

    return .failure(.missing)
}
