//
//  KeychainClient.swift
//  Streamie
//
//  Created by Mikhail Yurov on 22.12.2025.
//

import ComposableArchitecture
import Security

protocol KeychainClient {
    func save(_ value: String, for key: String) throws
    func load(_ key: String) throws -> String?
    func delete(_ key: String) throws
}

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
}

private enum KeychainClientKey: DependencyKey {
    static let liveValue: KeychainClient = KeychainClientLive()
}

extension DependencyValues {
    var keychainClient: KeychainClient {
        get { self[KeychainClientKey.self] }
        set { self[KeychainClientKey.self] = newValue }
    }
}


