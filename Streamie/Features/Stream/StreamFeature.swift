//
//  StreamFeature.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import ComposableArchitecture
import Foundation

struct StreamFeature: Reducer {

    // MARK: - State

    struct State: Equatable {
        let configuration: StreamConfiguration

        var status: StreamStatus = .idle
        var error: StreamingError?

        var isFrontCamera: Bool = true
        var isMicOn: Bool = true
        var isCameraOn: Bool = true

        var isInfoSheetPresented: Bool = false

        var startedAt: Date?
        var duration: TimeInterval = 0

        var videoBitrate: Int?
        var audioBitrate: Int?
    }

    // MARK: - Action

    enum Action: Equatable {
        case onAppear
        case onDisappear

        case startStopTapped
        case setFrontCamera(Bool)

        case toggleMic
        case toggleCamera

        case infoButtonTapped
        case infoSheetDismissed

        case streamStatusChanged(StreamStatus)
        case tick

        case errorAlertDismissed
        case backButtonTapped

        case delegate(Delegate)
    }

    enum Delegate: Equatable {
        case backToConfiguration
    }

    // MARK: - Dependencies

    @Dependency(\.streamClient) var streamClient
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                state.error = nil
                return .merge(
                    observeStreamStatus(),
                    startTimer()
                )

            case .onDisappear:
                return .run { _ in
                    await streamClient.stop()
                }

            case .startStopTapped:
                switch state.status {
                case .idle, .stopped, .failed:
                    state.startedAt = nil
                    state.duration = 0
                    return startStream(configuration: state.configuration)

                case .connecting, .live:
                    return .run { _ in
                        await streamClient.stop()
                    }
                }

            case let .streamStatusChanged(status):
                state.status = status

                if case let .live(metrics) = status {
                    state.videoBitrate = metrics?.videoBitrate
                    state.audioBitrate = metrics?.audioBitrate

                    if state.startedAt == nil {
                        state.startedAt = Date()
                    }
                }

                if case let .failed(error) = status {
                    state.error = error
                }

                return .none
            case .tick:
                if let startedAt = state.startedAt {
                    state.duration = Date().timeIntervalSince(startedAt)
                }
                return .none

            case let .setFrontCamera(isFront):
                state.isFrontCamera = isFront
                return .run { _ in
                    await streamClient.setCameraPosition(isFront ? .front : .back)
                }

            case .toggleMic:
                state.isMicOn.toggle()
                let isOn = state.isMicOn
                return .run { _ in
                    await streamClient.setMicrophoneEnabled(isOn)
                }

            case .toggleCamera:
                state.isCameraOn.toggle()
                let isOn = state.isCameraOn
                return .run { _ in
                    await streamClient.setCameraEnabled(isOn)
                }

            case .infoButtonTapped:
                state.isInfoSheetPresented = true
                return .none

            case .infoSheetDismissed:
                state.isInfoSheetPresented = false
                return .none

            case .errorAlertDismissed:
                state.error = nil
                return .none

            case .backButtonTapped:
                return .send(.delegate(.backToConfiguration))

            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Effects

    private func startStream(configuration: StreamConfiguration) -> Effect<Action> {
        .run { send in
            do {
                try await streamClient.start(configuration)
            } catch let error as StreamingError {
                await send(.streamStatusChanged(.failed(error)))
            } catch {
                await send(.streamStatusChanged(.failed(.unknown)))
            }
        }
    }

    private func observeStreamStatus() -> Effect<Action> {
        .run { send in
            for await status in streamClient.statuses() {
                await send(.streamStatusChanged(status))
            }
        }
    }

    private func startTimer() -> Effect<Action> {
        .run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.tick)
            }
        }
    }
}
