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

                return .merge(
                    startStream(configuration: state.configuration),
                    observeStreamStatus()
                )

            case .onDisappear:
                return .run { _ in
                    await streamClient.stop()
                }

            // MARK: - User intent

            case .stopTapped:
                guard state.status == .live || state.status == .connecting else {
                    return .none
                }

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

    private func startStream(configuration: StreamConfiguration) -> Effect<Action> {
        .run { _ in
            try await streamClient.start(configuration)
        }
    }

    private func observeStreamStatus() -> Effect<Action> {
        .run { send in
            for await status in streamClient.statuses() {
                await send(.streamStatusChanged(status))
            }
        }
    }
}
