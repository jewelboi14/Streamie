//
//  StreamingError.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import Foundation

enum StreamingError: Error, Equatable {
    case alreadyStreaming
    case notStreaming

    case cameraUnavailable
    case microphoneUnavailable
    case permissionsDenied(Permission)

    case rtmpConnectionFailed
    case rtmpPublishFailed

    case encoderInitializationFailed
    case unknown
}

enum Permission: Equatable {
    case camera
    case microphone
}
