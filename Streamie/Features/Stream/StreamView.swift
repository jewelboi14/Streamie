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

                if !viewStore.isCameraOn {
                    videoPlaceholder()
                }

                VStack {
                    topBar(viewStore)
                    Spacer()
                    bottomPanel(viewStore)
                }
            }
            .alert(
                isPresented: viewStore.binding(
                    get: { $0.error != nil },
                    send: .errorAlertDismissed
                )
            ) {
                Alert(
                    title: Text("Streaming error"),
                    message: Text(viewStore.error?.message ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
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
        }
    }
    
    // MARK: - Top Bar
    
    private func topBar(
        _ viewStore: ViewStore<StreamFeature.State, StreamFeature.Action>
    ) -> some View {
        HStack(spacing: 12) {
            
            if !viewStore.status.isLiveOrConnecting {
                circleButton(systemName: "chevron.left") {
                    viewStore.send(.backButtonTapped)
                }
            }
            
            Spacer()
            
            streamStatus(viewStore.status)
            
            circleButton(systemName: "info.circle") {
                viewStore.send(.infoButtonTapped)
            }
        }
        .padding()
    }
    
    // MARK: - Bottom Panel
    
    private func bottomPanel(
        _ viewStore: ViewStore<StreamFeature.State, StreamFeature.Action>
    ) -> some View {
        VStack(spacing: 20) {
            
            startStopButton(viewStore)
            
            HStack(spacing: 20) {
                
                circleButton(
                    systemName: viewStore.isMicOn ? "mic.fill" : "mic.slash.fill"
                ) {
                    viewStore.send(.toggleMic)
                }
                
                circleButton(systemName: "arrow.triangle.2.circlepath.camera") {
                    viewStore.send(.setFrontCamera(!viewStore.isFrontCamera))
                }
                
                circleButton(
                    systemName: viewStore.isCameraOn ? "video.fill" : "video.slash.fill"
                ) {
                    viewStore.send(.toggleCamera)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Start / Stop Button
    
    private func startStopButton(
        _ viewStore: ViewStore<StreamFeature.State, StreamFeature.Action>
    ) -> some View {
        
        let isLiveOrConnecting = viewStore.status.isLiveOrConnecting
        
        return Button {
            viewStore.send(.startStopTapped)
        } label: {
            Text(isLiveOrConnecting ? "Stop stream" : "Start stream")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isLiveOrConnecting ? Color.red : Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Components
    
    private func circleButton(
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
    
    private func streamStatus(_ status: StreamStatus) -> some View {
        Text(status.title)
            .font(.footnote.weight(.semibold))
            .foregroundColor(status.isLive ? .red : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
    
    private func videoPlaceholder() -> some View {
        ZStack {
            Color(.systemGray5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "video.slash.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }
    
}
