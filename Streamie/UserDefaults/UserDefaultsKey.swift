//
//  UserDefaultsKey.swift
//  Streamie
//
//  Created by Mikhail Yurov on 22.12.2025.
//

import ComposableArchitecture
import Foundation

private enum UserDefaultsKey: DependencyKey {
    static let liveValue: UserDefaults = .standard
}

extension DependencyValues {
    var userDefaults: UserDefaults {
        get { self[UserDefaultsKey.self] }
        set { self[UserDefaultsKey.self] = newValue }
    }
}
