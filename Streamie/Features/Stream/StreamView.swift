//
//  StreamView.swift
//  Streamie
//
//  Created by Mikhail Yurov on 21.12.2025.
//

import SwiftUI
import ComposableArchitecture

struct StreamView: View {
    
    let store: StoreOf<StreamFeature>
    
    var body: some View {
        WithViewStore(store, observe: \.status) { viewStore in
            VStack(spacing: 24) {
                
                Text("Streaming")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(statusTitle(for: viewStore.state))
                    .font(.headline)
                
                Button("Stop stream") {
                    viewStore.send(.stopTapped)
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func statusTitle(for status: StreamStatus) -> String {
        switch status {
        case .idle:
            return "Idle"
        case .connecting:
            return "Connecting…"
        case .live:
            return "Live"
        case .stopped:
            return "Stopped"
        case .failed:
            return "Failed"
        }
    }
}
