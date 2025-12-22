//
//  StreamInfoSheetView.swift
//  Streamie
//
//  Created by Mikhail Yurov on 21.12.2025.
//
//
import SwiftUI
import ComposableArchitecture

struct StreamInfoSheetView: View {
    
    let store: StoreOf<StreamFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                List {
                    Section(header: Text("Status")) {
                        infoRow(
                            title: "Connection",
                            value: statusTitle(for: viewStore.status)
                        )
                        
                        if case .live = viewStore.status {
                            infoRow(
                                title: "Broadcast time",
                                value: timeString(from: viewStore.duration)
                            )
                        }
                    }
                    
                    Section(header: Text("Stream")) {
                        infoRow(title: "Protocol", value: "RTMP")
                        infoRow(title: "Video codec", value: "H.264")
                        infoRow(title: "Audio codec", value: "AAC")
                        
                        if let bitrate = viewStore.videoBitrate {
                            infoRow(title: "Video bitrate", value: "\(bitrate) kbps")
                        }
                        
                        if let bitrate = viewStore.audioBitrate {
                            infoRow(title: "Audio bitrate", value: "\(bitrate) kbps")
                        }
                    }
                    
                    Section(header: Text("Input")) {
                        infoRow(
                            title: "Camera",
                            value: viewStore.isFrontCamera ? "Front" : "Back"
                        )
                        
                        infoRow(
                            title: "Microphone",
                            value: viewStore.isMicOn ? "Enabled" : "Muted"
                        )
                    }
                }
                .navigationTitle("Stream Info")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            viewStore.send(.infoSheetDismissed)
                        }
                    }
                }
            }
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
    
    private func statusTitle(for status: StreamStatus) -> String {
        switch status {
        case .idle: return "Idle"
        case .connecting: return "Connecting"
        case .live: return "Online"
        case .stopped: return "Stopped"
        case .failed: return "Failed"
        }
    }
    
    private func timeString(from duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
