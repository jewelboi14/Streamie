//
//  RouteReducer.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import ComposableArchitecture

struct RouteReducer: Reducer {

    typealias State = AppFeature.Route
    typealias Action = AppFeature.RouteAction

    var body: some Reducer<State, Action> {
        Scope(
            state: /State.configuration,
            action: /Action.configuration
        ) {
            ConfigurationFeature()
        }

        Scope(
            state: /State.stream,
            action: /Action.stream
        ) {
            StreamFeature()
        }
    }
}

