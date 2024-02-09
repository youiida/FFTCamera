//
//  ContentView.swift
//  FFTCamera
//
//  Created by 飯田優羽 on 2024/01/30.
//

import SwiftUI
import Accelerate
import UIKit

struct ContentView: View {
    @State private var showImagePicker: Bool = false
    @State private var image: Image? = nil
    @State private var uiImage: UIImage? = nil
    @State private var showActionSheet: Bool = false
    @State private var isProcessing: Bool = false
    @State private var fftGraphView: IntensityChartView? = nil // FFT結果のグラフを表示するための状態変数

    var body: some View {
        VStack {
            image?.resizable().scaledToFit()
            if let fftGraphView = fftGraphView {
                fftGraphView // FFTの結果を表示
            }
            if isProcessing {
                ActivityIndicator(isAnimating: $isProcessing, style: .large)
            } else {
                Button("カメラを開く") {
                    self.showImagePicker = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(uiImage: self.$uiImage, showActionSheet: self.$showActionSheet)
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("画像処理を選択"), buttons: [
                .default(Text("そのまま表示")) {
                    self.fftGraphView = nil // FFTのグラフ表示をリセット
                    self.image = Image(uiImage: self.uiImage!)
                },
                .default(Text("グレースケールに変換")) {
                    self.fftGraphView = nil // FFTのグラフ表示をリセット
                    self.image = Image(uiImage: ImgProc.convertToGrayscale(image: self.uiImage!))
                },
                .default(Text("2の累乗に切り取り")) {
                    self.fftGraphView = nil // FFTのグラフ表示をリセット
                    self.image = Image(uiImage: ImgProc.cropToPowerOfTwo(image: self.uiImage!))
                },
                .default(Text("FFT2D Image")) {
                    self.fftGraphView = nil // FFTのグラフ表示をリセット
                    self.isProcessing = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        let processedImage = ImgProc.fftImage(self.uiImage!)
                        DispatchQueue.main.async {
                            self.image = Image(uiImage: processedImage!)
                            self.isProcessing = false
                        }
                    }
                },
                .default(Text("FFT1D")){
                    self.isProcessing = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let fftResult = ImgProc.fftGraph(self.uiImage!) {
                            DispatchQueue.main.async {
                                // グレースケール画像を表示
                                self.image = Image(uiImage: fftResult.grayscale)
                                // FFTグラフビューを表示
                                self.fftGraphView = fftResult.chartView
                                self.isProcessing = false
                            }
                        }
                    }
                },
                .cancel {
                    self.fftGraphView = nil // FFTのグラフ表示をリセット
                    self.image = nil // 画像表示をリセット
                }
            ])
        }
    }
}


struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}


#Preview {
    ContentView()
}
