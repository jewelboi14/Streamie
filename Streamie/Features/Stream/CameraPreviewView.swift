//
//  CameraPreviewView.swift
//  Streamie
//
//  Created by Mikhail Yurov on 21.12.2025.
//


import SwiftUI
import HaishinKit

struct CameraPreviewView: UIViewRepresentable {

    let onConnect: @MainActor (MTHKView) -> Void

    func makeUIView(context: Context) -> MTHKView {
        let view = MTHKView(frame: .zero)
        onConnect(view)
        return view
    }

    func updateUIView(_ uiView: MTHKView, context: Context) {}
}

