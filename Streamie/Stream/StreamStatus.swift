//
//  StreamStatus.swift
//  Streamie
//
//  Created by Mikhail Yurov on 20.12.2025.
//

import Foundation

enum StreamStatus: Equatable {
    case idle
    case connecting
    case live
    case stopped
    case failed(StreamingError)
}
