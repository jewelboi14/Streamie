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

    // MARK: - Cancel IDs

    private enum CancelID {
        case timer
        case streamStatus
    }

    // MARK: - Dependencies

    @Dependency(\.streamClient) var streamClient
    @Dependency(\.continuousClock) var clock

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            // MARK: Lifecycle

            case .onAppear:
                state.error = nil
                return .merge(
                    observeStreamStatus(),
                    startTimer()
                )

            // MARK: Stream control

            case .startStopTapped:
                switch state.status {
                case .idle, .stopped, .failed:
                    state.startedAt = nil
                    state.duration = 0
                    return startStream(configuration: state.configuration)

                case .connecting, .live:
                    return stopStream()
                }

            // MARK: Stream updates

            case let .streamStatusChanged(status):
                state.status = status

                switch status {
                case let .live(metrics):
                    state.videoBitrate = metrics?.videoBitrate
                    state.audioBitrate = metrics?.audioBitrate
                    
                    if state.startedAt == nil {
                        state.startedAt = Date()
                    }
                case let .failed(error):
                    state.error = error
                default:
                    return .none
                }
                return .none
            case .tick:
                if let startedAt = state.startedAt {
                    state.duration = Date().timeIntervalSince(startedAt)
                }
                return .none

            // MARK: Controls

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

            // MARK: UI

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
                return .merge(
                    stopStream(),
                    stopObservingStreamStatus(),
                    .send(.delegate(.backToConfiguration))
                )
            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Effects

    private func startStream(configuration: StreamConfiguration) -> Effect<Action> {
        .run { send in
            await streamClient.start(configuration)
        }
    }

    private func stopStream() -> Effect<Action> {
        .merge(
            stopTimer(),
            .run { _ in
                await streamClient.stop()
            }
        )
    }

    private func observeStreamStatus() -> Effect<Action> {
        .run { send in
            for await status in streamClient.statuses() {
                await send(.streamStatusChanged(status))
            }
        }
        .cancellable(id: CancelID.streamStatus)
    }

    private func stopObservingStreamStatus() -> Effect<Action> {
        .cancel(id: CancelID.streamStatus)
    }

    private func startTimer() -> Effect<Action> {
        .run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.tick)
            }
        }
        .cancellable(id: CancelID.timer)
    }

    private func stopTimer() -> Effect<Action> {
        .cancel(id: CancelID.timer)
    }
}
