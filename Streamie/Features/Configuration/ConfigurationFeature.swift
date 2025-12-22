//
//  ConfigurationFeature.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import ComposableArchitecture

struct ConfigurationFeature: Reducer {
    
    // MARK: - State
    struct State: Equatable {
        var streamURL: String = "rtmp://live.twitch.tv/app"
        var streamKey: String = "live_1409804756_lCSDiiDXvFZo9xxnVIj4jtyeJdrILE"
        
        var isValid: Bool {
            !streamURL.isEmpty && !streamKey.isEmpty
        }
    }
    
    // MARK: - Action
    
    enum Action: Equatable {
        case streamURLChanged(String)
        case streamKeyChanged(String)
        case continueTapped
        
        case delegate(Delegate)
    }
    
    enum Delegate: Equatable {
        case didFinish(StreamConfiguration)
    }
    
    // MARK: - Reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case let .streamURLChanged(value):
                state.streamURL = value
                return .none
                
            case let .streamKeyChanged(value):
                state.streamKey = value
                return .none
                
            case .continueTapped:
                guard state.isValid else { return .none }
                
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
