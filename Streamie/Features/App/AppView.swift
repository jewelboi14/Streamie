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

    @Dependency(\.streamPreview) private var makeStreamPreview

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
                    action: Router.Action.stream
                ) { streamStore in

                    StreamView(
                        store: streamStore,
                        preview: makeStreamPreview()
                    )
                }
            }
        }
    }
}
