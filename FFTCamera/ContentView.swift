//
//  ContentView.swift
//  FFTCamera
//
//  Created by 飯田優羽 on 2024/01/30.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var image = UIImage(named: "sample")
    @State private var text: String?

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 200, height: 200)
                    .scaledToFit()
            }
            if let text = text {
                Text(text)
            }
            Button("to fft") {
                apply_fft()
            }
            Button("to grayscale") {
                apply_grayscale()
            }
            Button("clear") {
                image = UIImage(named: "sample")
                text = nil
            }
        }
        .padding()
    }

    private func apply_grayscale() {
        guard let source = UIImage(named: "sample") else {
            text = "画像の取得に失敗"
            return
        }
        guard let image = ImageProcessor.grayscale(image: source) else {
            text = "画像の変換に失敗"
            return
        }

        self.image = image
        text = nil
    }
    
    private func apply_fft() {
        guard let source = UIImage(named: "sample") else {
            text = "画像の取得に失敗"
            return
        }
        let image = FFTProcessor.fftImage(source)

        self.image = image
        text = nil
    }

}

#Preview {
    ContentView()
}
