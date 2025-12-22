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
        var error: String?
        
        var isFrontCamera: Bool = true
        var isMicOn: Bool = true
        var isCameraOn: Bool = true
        
        var isInfoSheetPresented: Bool = false
        
        var startedAt: Date?
        var duration: TimeInterval = 0
        
        var videoBitrate: Int?
        var audioBitrate: Int?
        var reconnectCount: Int?
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
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.streamClient) var streamClient
    @Dependency(\.continuousClock) var clock
    
    // MARK: - Reducer
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
                // MARK: - Lifecycle
                
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
                
                // MARK: - Start / Stop
                
            case .startStopTapped:
                switch state.status {
                case .idle, .stopped, .failed:
                    state.startedAt = nil
                    state.duration = 0
                    state.error = nil
                    
                    return startStream(configuration: state.configuration)
                    
                case .connecting, .live:
                    return .run { _ in
                        await streamClient.stop()
                    }
                }
                
                // MARK: - Stream events
                
            case let .streamStatusChanged(status):
                state.status = status
                
                if status == .live, state.startedAt == nil {
                    state.startedAt = Date()
                }
                
                if case let .failed(error) = status {
                    state.error = error.localizedDescription
                }
                
                return .none
                
            case .tick:
                if let startedAt = state.startedAt {
                    state.duration = Date().timeIntervalSince(startedAt)
                }
                return .none
                
                // MARK: - User intent
                
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
                
                // MARK: - Info sheet
                
            case .infoButtonTapped:
                state.isInfoSheetPresented = true
                return .none
                
            case .infoSheetDismissed:
                state.isInfoSheetPresented = false
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
    
    private func startTimer() -> Effect<Action> {
        .run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.tick)
            }
        }
    }
}
