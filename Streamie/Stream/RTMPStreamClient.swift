//
//  RTMPStreamClient.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import HaishinKit
import AVFoundation
import VideoToolbox
import UIKit

final class RTMPStreamClient: StreamClient {

    private let connection = RTMPConnection()
    private let stream: RTMPStream

    private var currentCameraPosition: CameraPosition = .front
    private var isMicrophoneEnabled: Bool = true

    private var isPreviewRunning: Bool = false
    private var isStreaming: Bool = false

    private var state: StreamStatus = .idle

    private let statusStream: AsyncStream<StreamStatus>
    private let continuation: AsyncStream<StreamStatus>.Continuation

    init() {
        self.stream = RTMPStream(connection: connection)

        let pair = AsyncStream.makeStream(of: StreamStatus.self)
        self.statusStream = pair.stream
        self.continuation = pair.continuation

        configureStream()
        observeEvents()

        continuation.yield(.idle)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        continuation.finish()
    }

    // MARK: - StreamClient API

    func start(_ configuration: StreamConfiguration) async throws {
        guard state == .idle || state == .stopped else { return }

        update(.connecting)
        isStreaming = true

        connection.connect(configuration.url)
        stream.publish(configuration.streamKey)
    }

    func stop() async {
        guard isStreaming else { return }

        isStreaming = false

        update(.stopped)

        stream.close()
        connection.close()
    }

    func setCameraPosition(_ position: CameraPosition) async {
        currentCameraPosition = position
        attachCamera(position: position)
    }

    func setMicrophoneEnabled(_ enabled: Bool) async {
        guard isMicrophoneEnabled != enabled else { return }
        isMicrophoneEnabled = enabled

        if enabled {
            attachMicrophone()
        } else {
            stream.attachAudio(nil)
        }
    }

    func setCameraEnabled(_ enabled: Bool) async {
        if enabled {
            attachCamera(position: currentCameraPosition)
        } else {
            stream.attachCamera(nil)
        }
    }

    nonisolated func statuses() -> AsyncStream<StreamStatus> {
        statusStream
    }

    // MARK: - Camera preview (UI-side)

    func attachPreview(_ view: MTHKView) {
        view.videoGravity = .resizeAspectFill
        view.attachStream(stream)

        startPreviewIfNeeded()
    }

    private func startPreviewIfNeeded() {
        guard !isPreviewRunning else { return }

        attachCamera(position: currentCameraPosition)
        if isMicrophoneEnabled {
            attachMicrophone()
        }

        isPreviewRunning = true
    }
}


// MARK: - Configuration

private extension RTMPStreamClient {

    func configureStream() {
        stream.videoSettings = VideoCodecSettings(
            videoSize: CGSize(width: 1280, height: 720),
            bitRate: 3_000_000,
            profileLevel: kVTProfileLevel_H264_Main_AutoLevel as String,
            scalingMode: .trim,
            bitRateMode: .average,
            maxKeyFrameIntervalDuration: 2,
            allowFrameReordering: false,
            dataRateLimits: nil,
            isHardwareEncoderEnabled: true
        )

        stream.audioSettings = AudioCodecSettings(
            bitRate: 128_000
        )
    }

    func attachCamera(position: CameraPosition) {
        let devicePosition: AVCaptureDevice.Position =
            position == .front ? .front : .back

        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: devicePosition
        ) else {
            receive(.cameraUnavailable)
            return
        }

        stream.attachCamera(camera)
    }

    func attachMicrophone() {
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            receive(.microphoneUnavailable)
            return
        }

        stream.attachAudio(microphone)
    }
}

// MARK: - RTMP events

private extension RTMPStreamClient {

    func observeEvents() {
        connection.addEventListener(
            .rtmpStatus,
            selector: #selector(handleRTMPEvent),
            observer: self,
            useCapture: false
        )
    }

    @objc
    func handleRTMPEvent(_ notification: Notification) {
        let event = Event.from(notification)

        guard
            let data = event.data as? [String: Any],
            let code = data["code"] as? String
        else {
            return
        }

        switch code {

        case RTMPConnection.Code.connectSuccess.rawValue:
            receive(.connectionSuccess)

        case RTMPConnection.Code.connectFailed.rawValue,
             RTMPConnection.Code.connectRejected.rawValue,
             RTMPConnection.Code.connectInvalidApp.rawValue:
            receive(.connectionFailed)

        case RTMPConnection.Code.connectClosed.rawValue,
             RTMPConnection.Code.connectIdleTimeOut.rawValue:
            receive(.connectionClosed)

        case RTMPStream.Code.publishStart.rawValue:
            receive(.publishStarted)

        case RTMPStream.Code.publishBadName.rawValue:
            receive(.publishRejected)

        case RTMPStream.Code.publishIdle.rawValue:
            receive(.publishStopped)

        default:
            break
        }
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
