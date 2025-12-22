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
        var error: ConfigurationError?

        var isValid: Bool {
            !streamURL.isEmpty && !streamKey.isEmpty && isValidRTMPURL
        }

        var isValidRTMPURL: Bool {
            guard !streamURL.isEmpty else { return true }
            return streamURL.lowercased().hasPrefix("rtmp://") ||
                   streamURL.lowercased().hasPrefix("rtmps://")
        }
    }

    // MARK: - Error
    enum ConfigurationError: Error, Equatable {
        case invalidURL
        case keychainLoadFailed
        case keychainSaveFailed
    }

    // MARK: - Action
    enum Action: Equatable {
        case onAppear

        case streamURLChanged(String)
        case streamKeyChanged(String)
        case continueTapped

        case errorAlertDismissed
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

                do {
                    state.streamKey = try keychain.load(StreamStorageKeys.streamKey) ?? ""
                } catch {
                    print("[ConfigurationFeature] Failed to load stream key: \(error)")
                    state.error = .keychainLoadFailed
                }

                return .none

            case let .streamURLChanged(value):
                state.streamURL = value
                state.error = nil
                return .none

            case let .streamKeyChanged(value):
                state.streamKey = value
                return .none

            case .continueTapped:
                guard !state.streamURL.isEmpty, !state.streamKey.isEmpty else {
                    return .none
                }

                guard state.isValidRTMPURL else {
                    state.error = .invalidURL
                    return .none
                }

                userDefaults.set(
                    state.streamURL,
                    forKey: StreamStorageKeys.streamURL
                )

                do {
                    try keychain.save(
                        state.streamKey,
                        for: StreamStorageKeys.streamKey
                    )
                } catch {
                    print("[ConfigurationFeature] Failed to save stream key: \(error)")
                    state.error = .keychainSaveFailed
                    return .none
                }

                let config = StreamConfiguration(
                    url: state.streamURL,
                    streamKey: state.streamKey
                )

                return .send(.delegate(.didFinish(config)))

            case .errorAlertDismissed:
                state.error = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
