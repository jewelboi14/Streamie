//
//  StreamingSDKEvent.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import Foundation

enum StreamingSDKEvent: Equatable {
    case connectionSuccess
    case connectionFailed
    case connectionClosed

    case publishStarted
    case publishStopped
    case publishRejected

    case cameraUnavailable
    case microphoneUnavailable
    case permissionDenied(Permission)
}
