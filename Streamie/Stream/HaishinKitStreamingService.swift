//
//  HaishinKitStreamingService.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import HaishinKit
import AVFoundation
import VideoToolbox

final class HaishinKitStreamingService {

    var onEvent: ((StreamingSDKEvent) async -> Void)?

    private let connection = RTMPConnection()
    private let stream: RTMPStream

    init() {
        self.stream = RTMPStream(connection: connection)
        configureStream()
        observeEvents()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start(rtmpURL: String, streamKey: String) {
        attachDevices()
        connection.connect(rtmpURL)
        stream.publish(streamKey)
    }

    func stop() {
        stream.close()
        connection.close()
    }
}

// MARK: - Service internals

private extension HaishinKitStreamingService {

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

    func attachDevices() {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            emit(.cameraUnavailable)
            return
        }

        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            emit(.microphoneUnavailable)
            return
        }

        stream.attachCamera(camera)
        stream.attachAudio(microphone)
    }

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
            emit(.connectionSuccess)

        case RTMPConnection.Code.connectFailed.rawValue,
             RTMPConnection.Code.connectRejected.rawValue,
             RTMPConnection.Code.connectInvalidApp.rawValue:
            emit(.connectionFailed)

        case RTMPConnection.Code.connectClosed.rawValue,
             RTMPConnection.Code.connectIdleTimeOut.rawValue:
            emit(.connectionClosed)

        case RTMPStream.Code.publishStart.rawValue:
            emit(.publishStarted)

        case RTMPStream.Code.publishBadName.rawValue:
            emit(.publishRejected)

        case RTMPStream.Code.publishIdle.rawValue:
            emit(.publishStopped)

        default:
            break
        }
    }

    func emit(_ event: StreamingSDKEvent) {
        guard let onEvent else { return }
        Task {
            await onEvent(event)
        }
    }
}
