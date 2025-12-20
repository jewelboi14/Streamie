//
//  StreamClient.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import ComposableArchitecture

protocol StreamClient {
    func start(_ configuration: StreamConfiguration) async throws
    func stop() async

    func statuses() -> AsyncStream<StreamStatus>
}

private enum StreamClientKey: DependencyKey {
    static let liveValue: StreamClient = RTMPStreamClient()
}

extension DependencyValues {
    var streamClient: StreamClient {
        get { self[StreamClientKey.self] }
        set { self[StreamClientKey.self] = newValue }
    }
}
