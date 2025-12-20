//
//  AppFeature.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import ComposableArchitecture

struct AppFeature: Reducer {

    struct State: Equatable {
        var route: Route = .configuration(ConfigurationFeature.State())
    }

    enum Route: Equatable {
        case configuration(ConfigurationFeature.State)
        case stream(StreamFeature.State)
    }

    enum Action {
        case route(RouteAction)
    }

    enum RouteAction {
        case configuration(ConfigurationFeature.Action)
        case stream(StreamFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(
            state: \.route,
            action: /Action.route
        ) {
            RouteReducer()
        }
    }
}

