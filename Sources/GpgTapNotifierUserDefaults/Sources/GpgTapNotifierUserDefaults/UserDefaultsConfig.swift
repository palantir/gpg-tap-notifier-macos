// Copyright 2022 Palantir Technologies, Inc. All rights reserved.
// Licensed under the Apache License, Version 2.0.

import Foundation

public struct UserDefaultsConfig<T> {
    public let key: String
    public let getDefault: () -> T
}
