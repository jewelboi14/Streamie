//
//  StreamFeature.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import ComposableArchitecture

struct StreamFeature: Reducer {

    // MARK: - State
    struct State: Equatable {
        let configuration: StreamConfiguration
        var status: StreamStatus = .idle
        var error: String?
    }

    // MARK: - Action
    enum Action: Equatable {
        case onAppear
        case onDisappear
        case startTapped
        case stopTapped
        case streamStatusChanged(StreamStatus)
    }

    // MARK: - Dependencies
    @Dependency(\.streamClient) var streamClient

    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: - Lifecycle

            case .onAppear:
                state.status = .idle
                state.error = nil
                return observeStreamStatus()
            case .onDisappear:
                return .run { _ in
                    await streamClient.stop()
                }

            // MARK: - User intent

            case .startTapped:  
                guard state.status == .idle else { return .none }
                state.error = nil

                return .run { [config = state.configuration] _ in
                    try await streamClient.start(config)
                }

            case .stopTapped:
                guard state.status == .live else { return .none }

                return .run { _ in
                    await streamClient.stop()
                }

            // MARK: - Stream events

            case let .streamStatusChanged(status):
                state.status = status

                if case let .failed(error) = status {
                    state.error = error.localizedDescription
                }

                return .none
            }
        }
    }

    // MARK: - Effects

    private func observeStreamStatus() -> Effect<Action> {
        .run { send in
            for await status in streamClient.statuses() {
                await MainActor.run {
                    send(.streamStatusChanged(status))
                }
            }
        }
    }
}
