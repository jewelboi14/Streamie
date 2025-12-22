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

extension StreamingError {
    var title: String {
        switch self {
        case .permissionsDenied:
            return "Permission required"
        default:
            return "Streaming error"
        }
    }

    var message: String {
        switch self {
        case .alreadyStreaming:
            return "Stream is already running."

        case .notStreaming:
            return "Stream is not running."

        case .cameraUnavailable:
            return "Camera is not available on this device."

        case .microphoneUnavailable:
            return "Microphone is not available."

        case let .permissionsDenied(permission):
            switch permission {
            case .camera:
                return "Camera access is denied. Please enable it in Settings."
            case .microphone:
                return "Microphone access is denied. Please enable it in Settings."
            }

        case .rtmpConnectionFailed:
            return "Failed to connect to the RTMP server."

        case .rtmpPublishFailed:
            return "Failed to publish the stream."

        case .encoderInitializationFailed:
            return "Failed to initialize video encoder."

        case .unknown:
            return "An unknown error occurred."
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .permissionsDenied, .cameraUnavailable, .microphoneUnavailable:
            return false
        default:
            return true
        }
    }
}

enum Permission: Equatable {
    case camera
    case microphone
}
