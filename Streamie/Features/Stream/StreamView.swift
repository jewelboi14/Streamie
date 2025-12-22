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
    let preview: CameraPreviewView

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {

                preview
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    bottomPanel(viewStore)
                }
            }
            .sheet(
                isPresented: viewStore.binding(
                    get: \.isInfoSheetPresented,
                    send: .infoSheetDismissed
                )
            ) {
                StreamInfoSheetView(store: store)
            }
            .onAppear { viewStore.send(.onAppear) }
            .onDisappear { viewStore.send(.onDisappear) }
        }
    }

    private func bottomPanel(
        _ viewStore: ViewStore<StreamFeature.State, StreamFeature.Action>
    ) -> some View {
        VStack(spacing: 16) {
            startStopButton(viewStore)
            HStack(spacing: 16) {

                Button {
                    viewStore.send(.toggleMic)
                } label: {
                    Image(systemName: viewStore.isMicOn ? "mic.fill" : "mic.slash.fill")
                }
                
                Button {
                    viewStore.send(.setFrontCamera(!viewStore.isFrontCamera))
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                }

                Button {
                    viewStore.send(.toggleCamera)
                } label: {
                    Image(systemName: viewStore.isCameraOn ? "video.fill" : "video.slash.fill")
                }
                
                Spacer()

                Text(statusTitle(for: viewStore.status))
                    .font(.footnote)
                    .foregroundColor(viewStore.status == .live ? .red : .secondary)

                Button {
                    viewStore.send(.infoButtonTapped)
                } label: {
                    Image(systemName: "info.circle")
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
    
    private func startStopButton(
        _ viewStore: ViewStore<StreamFeature.State, StreamFeature.Action>
    ) -> some View {

        let isLiveOrConnecting =
            viewStore.status == .live || viewStore.status == .connecting

        return Button {
            viewStore.send(.startStopTapped)
        } label: {
            Text(isLiveOrConnecting ? "Stop stream" : "Start stream")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isLiveOrConnecting ? Color.red : Color.green)
                .cornerRadius(10)
        }
    }

    private func statusTitle(for status: StreamStatus) -> String {
        switch status {
        case .idle: return "Idle"
        case .connecting: return "Connecting"
        case .live: return "LIVE"
        case .stopped: return "Stopped"
        case .failed: return "Failed"
        }
    }
}
