//
//  AppView.swift
//  Streamie
//
//  Created by Mikhail Yurov on 21.12.2025.
//


import SwiftUI
import ComposableArchitecture

struct AppView: View {

    let store: StoreOf<AppFeature>

    // NOTE (Routing / TCA):
    //
    // `SwitchStore` is intentionally combined with an explicit `switch state`.
    // This guarantees that exactly one `CaseLet` is rendered at any given time.
    //
    // Without this explicit switch, SwiftUI may keep a previous `CaseLet`
    // alive for one render pass after an enum state transition, which causes
    // TCA to emit a runtime diagnostic warning.
    //
    // This pattern is the recommended production approach for enum-based routing
    // in TCA and fully avoids transient `CaseLet` mismatch warnings while keeping
    // reducer scoping explicit and type-safe.
    var body: some View {
        SwitchStore(
            store.scope(
                state: \.router,
                action: AppFeature.Action.router
            )
        ) { state in

            switch state {

            case .configuration:
                CaseLet(
                    /Router.State.configuration,
                    action: Router.Action.configuration,
                    then: ConfigurationView.init
                )

            case .stream:
                CaseLet(
                    /Router.State.stream,
                    action: Router.Action.stream,
                    then: StreamView.init
                )
            }
        }
    }
}


