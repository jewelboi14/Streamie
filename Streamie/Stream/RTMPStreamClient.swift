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
    
    private weak var previewView: MTHKView?

    // MARK: - RTMP session (one per stream attempt)

    private var connection: RTMPConnection?
    private var stream: RTMPStream?

    // MARK: - State

    private var currentCameraPosition: CameraPosition = .front

    private var isMicrophoneEnabled: Bool = true
    private var isCameraEnabled: Bool = true

    private var isPreviewRunning: Bool = false
    private var isStreaming: Bool = false

    private var metricsTask: Task<Void, Never>?

    private var state: StreamStatus = .idle

    // MARK: - Status stream

    private let statusStream: AsyncStream<StreamStatus>
    private let continuation: AsyncStream<StreamStatus>.Continuation

    // MARK: - Init / Deinit

    init() {
        let pair = AsyncStream.makeStream(of: StreamStatus.self)
        self.statusStream = pair.stream
        self.continuation = pair.continuation

        createSession()
        continuation.yield(.idle)
    }

    deinit {
        teardownSession()
        continuation.finish()
    }

    // MARK: - StreamClient API

    func start(_ configuration: StreamConfiguration) async {
        guard
            !isStreaming,
            state == .idle || state == .stopped,
            let connection,
            let stream
        else { return }

        isStreaming = true
        update(.connecting)

        connection.connect(configuration.url)
        stream.publish(configuration.streamKey)
    }

    func stop() async {
        guard isStreaming else { return }

        isStreaming = false

        teardownSession()
        createSession()

        update(.stopped)
    }

    func setCameraPosition(_ position: CameraPosition) async {
        currentCameraPosition = position
        attachCamera(position: position)
    }

    func setMicrophoneEnabled(_ enabled: Bool) async {
        isMicrophoneEnabled = enabled
        stream?.audioMixerSettings.isMuted = !enabled
    }

    func setCameraEnabled(_ enabled: Bool) async {
        isCameraEnabled = enabled
        stream?.videoMixerSettings.isMuted = !enabled
    }

    nonisolated func statuses() -> AsyncStream<StreamStatus> {
        statusStream
    }

    // MARK: - Preview

    func attachPreview(_ view: MTHKView) {
        previewView = view

        view.videoGravity = .resizeAspectFill
        view.attachStream(stream)

        startPreviewIfNeeded()
    }

    private func startPreviewIfNeeded() {
        guard !isPreviewRunning else { return }

        attachCamera(position: currentCameraPosition)
        attachMicrophone()

        isPreviewRunning = true
    }
}

// MARK: - Session lifecycle

private extension RTMPStreamClient {

    func createSession() {
        let connection = RTMPConnection()
        let stream = RTMPStream(connection: connection)
        
        self.connection = connection
        self.stream = stream
        
        configureStream()
        observeEvents()
        
        isPreviewRunning = false
        
        if let previewView {
            previewView.attachStream(stream)
            startPreviewIfNeeded()
        }
    }

    func teardownSession() {
        stopMetricsTask()
        
        if let connection {
            connection.removeEventListener(
                .rtmpStatus,
                selector: #selector(handleRTMPEvent),
                observer: self
            )
            connection.close()
        }

        stream?.close()

        connection = nil
        stream = nil
    }
}

// MARK: - Configuration

private extension RTMPStreamClient {

    func configureStream() {
        guard let stream else { return }

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
        guard let stream else { return }

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

        stream.attachCamera(camera) { unit, _ in
            unit?.isVideoMirrored = position == .front
        }

        Task {
            await setCameraEnabled(isCameraEnabled)
        }
    }

    func attachMicrophone() {
        guard let stream else { return }

        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            receive(.microphoneUnavailable)
            return
        }

        stream.attachAudio(microphone)

        Task {
            await setMicrophoneEnabled(isMicrophoneEnabled)
        }
    }
}

// MARK: - Metrics

private extension RTMPStreamClient {

    func startMetricsTask() {
        metricsTask?.cancel()

        metricsTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard
                    case .live = self.state,
                    let stream = self.stream
                else { continue }

                let metrics = StreamMetrics(
                    videoBitrate: stream.videoSettings.bitRate,
                    audioBitrate: stream.audioSettings.bitRate
                )

                self.continuation.yield(.live(metrics))
            }
        }
    }

    func stopMetricsTask() {
        metricsTask?.cancel()
        metricsTask = nil
    }
}

// MARK: - RTMP events

private extension RTMPStreamClient {

    func observeEvents() {
        connection?.addEventListener(
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
            update(.live(nil))
            
        case (.live, .connectionClosed):
            update(.stopped)
            stopMetricsTask()
            
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

        if state.isLive && !newState.isLive {
            stopMetricsTask()
        }

        if !state.isLive && newState.isLive {
            startMetricsTask()
        }

        state = newState
        continuation.yield(newState)
    }
}
