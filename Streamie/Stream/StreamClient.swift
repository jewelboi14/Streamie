//
//  StreamClient.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import ComposableArchitecture
import HaishinKit
import SwiftUI

// MARK: - Domain protocol (used by Reducers)

protocol StreamClient {
    func start(_ configuration: StreamConfiguration) async throws
    func stop() async
    func attachPreview(_ view: MTHKView)
    func setCameraPosition(_ position: CameraPosition) async
    func setMicrophoneEnabled(_ enabled: Bool) async
    func setCameraEnabled(_ enabled: Bool) async

    func statuses() -> AsyncStream<StreamStatus>
}


// MARK: - Dependency Key

private enum StreamClientKey: DependencyKey {

    static let liveValue: StreamClientBox = {
        let client = RTMPStreamClient()

        let makePreview = {
            CameraPreviewView { view in
                client.attachPreview(view)
            }
        }

        return StreamClientBox(
            client: client,
            makePreview: makePreview
        )
    }()
}

// MARK: - Box (single instance holder)

struct StreamClientBox {
    let client: StreamClient
    let makePreview: () -> CameraPreviewView
}

// MARK: - DependencyValues

extension DependencyValues {

    var streamClient: StreamClient {
        get { self[StreamClientKey.self].client }
        set {
            let old = self[StreamClientKey.self]
            self[StreamClientKey.self] = StreamClientBox(
                client: newValue,
                makePreview: old.makePreview
            )
        }
    }

    var streamPreview: () -> CameraPreviewView {
        self[StreamClientKey.self].makePreview
    }
}

// MARK: - Camera Position

enum CameraPosition {
    case front
    case back
}
