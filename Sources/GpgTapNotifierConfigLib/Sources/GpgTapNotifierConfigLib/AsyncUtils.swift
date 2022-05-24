// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

struct ReadFileError: Error {
    let errorCode: NSNumber
}

func readFile(_ handle: FileHandle) async throws -> NSData {
    try await withCheckedThrowingContinuation { continuation in
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleReadToEndOfFileCompletion, object: handle, queue: .main) { notification in

            // Setting a token and removing it on the first observer trigger is a common pattern listed in Apple docs:
            // https://developer.apple.com/documentation/foundation/notificationcenter/1411723-addobserver#discussion
            if let token = token {
                NotificationCenter.default.removeObserver(token)
            }

            // This dictionary is expected to by present for NSFileHandleReadToEndOfFileCompletion.
            let userInfo = notification.userInfo!

            if let handleError = userInfo["NSFileHandleError"] {
                // Apple docs state this is expected to be an NSNumber.
                let code = handleError as! NSNumber

                continuation.resume(throwing: ReadFileError(errorCode: code))
                return
            }

            let data = userInfo[NSFileHandleNotificationDataItem] as! NSData
            continuation.resume(returning: data)
        }

        handle.readToEndOfFileInBackgroundAndNotify()
    }
}
