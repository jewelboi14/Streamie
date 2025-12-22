//
//  ConfigurationFeature.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import ComposableArchitecture
import Foundation

struct ConfigurationFeature: Reducer {

    // MARK: - State
    struct State: Equatable {
        var streamURL: String = ""
        var streamKey: String = ""

        var isValid: Bool {
            !streamURL.isEmpty && !streamKey.isEmpty
        }
    }

    // MARK: - Action
    enum Action: Equatable {
        case onAppear

        case streamURLChanged(String)
        case streamKeyChanged(String)
        case continueTapped

        case delegate(Delegate)
    }

    enum Delegate: Equatable {
        case didFinish(StreamConfiguration)
    }

    // MARK: - Dependencies
    @Dependency(\.keychainClient) var keychain
    @Dependency(\.userDefaults) var userDefaults

    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                state.streamURL =
                    userDefaults.string(forKey: StreamStorageKeys.streamURL) ?? ""

                state.streamKey =
                    (try? keychain.load(StreamStorageKeys.streamKey)) ?? ""

                return .none

            case let .streamURLChanged(value):
                state.streamURL = value
                return .none

            case let .streamKeyChanged(value):
                state.streamKey = value
                return .none

            case .continueTapped:
                guard state.isValid else { return .none }

                userDefaults.set(
                    state.streamURL,
                    forKey: StreamStorageKeys.streamURL
                )

                try? keychain.save(
                    state.streamKey,
                    for: StreamStorageKeys.streamKey
                )

                let config = StreamConfiguration(
                    url: state.streamURL,
                    streamKey: state.streamKey
                )

                return .send(.delegate(.didFinish(config)))

            case .delegate:
                return .none
            }
        }
    }
}
