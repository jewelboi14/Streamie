//
//  ConfigurationView.swift
//  Streamie
//
//  Created by Mikhail Yurov on 21.12.2025.
//

import SwiftUI
import ComposableArchitecture

struct ConfigurationView: View {
    
    let store: StoreOf<ConfigurationFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 24) {
                
                Text("Stream configuration")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    TextField(
                        "RTMP URL",
                        text: viewStore.binding(
                            get: \.streamURL,
                            send: ConfigurationFeature.Action.streamURLChanged
                        )
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    
                    SecureField(
                        "Stream key",
                        text: viewStore.binding(
                            get: \.streamKey,
                            send: ConfigurationFeature.Action.streamKeyChanged
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                }
                
                Button("Continue") {
                    viewStore.send(.continueTapped)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
