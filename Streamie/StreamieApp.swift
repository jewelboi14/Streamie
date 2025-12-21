//
//  StreamieApp.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import SwiftUI
import ComposableArchitecture

@main
struct StreamieApp: App {

    let store = Store(
        initialState: AppFeature.State(),
        reducer: {
            AppFeature()
        }
    )

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
