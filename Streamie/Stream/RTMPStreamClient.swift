//
//  RTMPStreamClient.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import Foundation

actor RTMPStreamClient: StreamClient {

    // MARK: - Private

    private let service: HaishinKitStreamingService
    private var state: StreamStatus = .idle

    private let stream: AsyncStream<StreamStatus>
    private let continuation: AsyncStream<StreamStatus>.Continuation

    // MARK: - Init

    init(service: HaishinKitStreamingService = .init()) {
        self.service = service

        let pair = AsyncStream.makeStream(of: StreamStatus.self)
        self.stream = pair.stream
        self.continuation = pair.continuation

        continuation.yield(.idle)

        self.service.onEvent = { [weak self] event in
            guard let self else { return }
            await self.receive(event)
        }
    }

    deinit {
        continuation.finish()
    }

    // MARK: - StreamClient

    func start(_ configuration: StreamConfiguration) async throws {
        guard state == .idle else { return }
        update(.connecting)
        service.start(
            rtmpURL: configuration.url,
            streamKey: configuration.streamKey
        )
    }

    func stop() async {
        guard state == .connecting || state == .live else { return }
        update(.stopped)
        service.stop()
    }

    nonisolated func statuses() -> AsyncStream<StreamStatus> {
        stream
    }
}

// MARK: - State machine

private extension RTMPStreamClient {

    func receive(_ event: StreamingSDKEvent) {
        switch (state, event) {

        case (.idle, .connectionSuccess):
            update(.connecting)

        case (.connecting, .publishStarted):
            update(.live)

        case (.live, .connectionClosed):
            update(.stopped)

        case (.connecting, .connectionFailed):
            update(.failed(.rtmpConnectionFailed))

        case (.connecting, .publishRejected):
            update(.failed(.rtmpPublishFailed))
        case (_, .cameraUnavailable):
            update(.failed(.cameraUnavailable))
        case (_, .microphoneUnavailable):
            update(.failed(.microphoneUnavailable))
        default:
            break
        }
    }

    func update(_ newState: StreamStatus) {
        guard state != newState else { return }
        state = newState
        continuation.yield(newState)
    }
}
