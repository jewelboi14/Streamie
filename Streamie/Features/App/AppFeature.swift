//
//  AppFeature.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import ComposableArchitecture

struct AppFeature: Reducer {
    
    struct State: Equatable {
        var router: Router.State = .configuration(
            ConfigurationFeature.State()
        )
    }

    @CasePathable
    enum Action {
        case router(Router.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(
            state: \.router,
            action: \.router
        ) {
            Router()
        }
    }
}
