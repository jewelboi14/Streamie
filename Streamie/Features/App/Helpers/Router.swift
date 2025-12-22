//
//  Router.swift
//  Streamie
//
//  Created by Mikhail Yurov on 21.12.2025.
//

import ComposableArchitecture

struct Router: Reducer {
    /* I decided to add a separate Router entity in case we need something like onboarding, or effects,
    because routing logic can be complicated in this kind of apps, however,
    in this project it's just nice-to-have, not necessary for MVP tho :) */
    
    // MARK: - Route (navigation state)

    @CasePathable
    enum State: Equatable {
        case configuration(ConfigurationFeature.State)
        case stream(StreamFeature.State)
        // future:
        // case streamChat
        // case effects
        // case onboarding
    }

    // MARK: - Action (navigation actions)

    @CasePathable
    enum Action {
        case configuration(ConfigurationFeature.Action)
        case stream(StreamFeature.Action)
    }

    // MARK: - Reducer

    var body: some Reducer<State, Action> {

        Scope(
            state: \.configuration,
            action: \.configuration
        ) {
            ConfigurationFeature()
        }
        
        Scope(
            state: \.stream,
            action: \.stream
        ) {
            StreamFeature()
        }
        
        Reduce { state, action in
            switch action {
                
                // Configuration → Stream
            case let .configuration(.delegate(.didFinish(config))):
                state = .stream(
                    StreamFeature.State(configuration: config)
                )
                return .none
                
                // Stream → Configuration
            case .stream(.delegate(.backToConfiguration)):
                state = .configuration(
                    ConfigurationFeature.State()
                )
                return .none
                
            case .configuration:
                return .none
                
            case .stream:
                return .none
            }
        }
    }
}
