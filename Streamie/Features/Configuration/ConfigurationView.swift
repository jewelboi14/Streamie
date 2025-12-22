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
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(
                            "RTMP URL (e.g. rtmp://...)",
                            text: viewStore.binding(
                                get: \.streamURL,
                                send: ConfigurationFeature.Action.streamURLChanged
                            )
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                        if !viewStore.streamURL.isEmpty && !viewStore.isValidRTMPURL {
                            Text("URL must start with rtmp:// or rtmps://")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

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
                .disabled(!viewStore.isValid)
            }
            .padding()
            .onAppear {
                viewStore.send(.onAppear)
            }
            .alert(
                "Error",
                isPresented: viewStore.binding(
                    get: { $0.error != nil },
                    send: .errorAlertDismissed
                ),
                actions: {
                    Button("OK", role: .cancel) {}
                },
                message: {
                    Text(errorMessage(for: viewStore.error))
                }
            )
        }
    }

    private func errorMessage(for error: ConfigurationFeature.ConfigurationError?) -> String {
        switch error {
        case .invalidURL:
            return "Please enter a valid RTMP URL starting with rtmp:// or rtmps://"
        case .keychainLoadFailed:
            return "Failed to load saved credentials. Please enter your stream key again."
        case .keychainSaveFailed:
            return "Failed to save your stream key securely. Please try again."
        case .none:
            return ""
        }
    }
}
