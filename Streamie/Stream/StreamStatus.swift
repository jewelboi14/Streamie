//
//  StreamStatus.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

enum StreamStatus: Equatable {
    case idle
    case connecting
    case live(StreamMetrics?)
    case stopped
    case failed(StreamingError)
}

extension StreamStatus {

    var isLive: Bool {
        if case .live = self { return true }
        return false
    }

    var isConnecting: Bool {
        if case .connecting = self { return true }
        return false
    }

    var isLiveOrConnecting: Bool {
        switch self {
        case .live, .connecting:
            return true
        default:
            return false
        }
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    var errorMessage: String? {
        if case let .failed(error) = self {
            return error.message
        }
        return nil
    }

    var title: String {
        switch self {
        case .idle:
            return "Idle"
        case .connecting:
            return "Connecting"
        case .live:
            return "LIVE"
        case .stopped:
            return "Stopped"
        case .failed:
            return "Failed"
        }
    }
}

struct StreamMetrics: Equatable {
    let videoBitrate: Int?
    let audioBitrate: Int?
}
