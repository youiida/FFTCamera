//
//  ImageControl.swift
//  FFTCamera
//
//  Created by 飯田優羽 on 2024/01/30.
//

import SwiftUI
import Charts
import UIKit
import Accelerate


struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var uiImage: UIImage?
    @Binding var showActionSheet: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.uiImage = uiImage
                parent.presentationMode.wrappedValue.dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.parent.showActionSheet = true
                }
            } else {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}


enum ImgProc {
    // グレースケール変換
    static func convertToGrayscale(image: UIImage) -> UIImage {
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIPhotoEffectNoir")
        let beginImage = CIImage(image: image)
        currentFilter?.setValue(beginImage, forKey: kCIInputImageKey)

        if let output = currentFilter?.outputImage,
           let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg)
        }
        return image
    }

    // 画像を2のべき乗サイズにトリミング
    static func cropToPowerOfTwo(image: UIImage) -> UIImage {
        let originalSize = image.size
        let widthPowerOfTwo = pow(2, floor(log2(originalSize.width)))
        let heightPowerOfTwo = pow(2, floor(log2(originalSize.height)))
        let cropSize = min(widthPowerOfTwo, heightPowerOfTwo)
        let cropRect = CGRect(x: (originalSize.width - cropSize) / 2,
                              y: (originalSize.height - cropSize) / 2,
                              width: cropSize,
                              height: cropSize)

        if let cgImage = image.cgImage,
           let croppedCgImage = cgImage.cropping(to: cropRect) {
            return UIImage(cgImage: croppedCgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        return image
    }

    // グレースケールのピクセルデータを抽出
    static func getGrayscalePixels(from image: UIImage) -> [[Complex]]? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        var rawData = [UInt8](repeating: 0, count: width * height)
        let context = CGContext(data: &rawData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var complexData = [[Complex]](repeating: [Complex](repeating: Complex(0, 0), count: width), count: height)
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * width + x
                complexData[y][x] = Complex(Double(rawData[pixelIndex]), 0)
            }
        }
        return complexData
    }

    // FFTの結果をUIImageに変換
    static func imageFromFFTResult(_ fftData: [[Complex]]) -> UIImage? {
        let height = fftData.count
        let width = fftData[0].count
        var rawData = [UInt8](repeating: 0, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let magnitude = fftData[y][x].magnitude()
                rawData[y * width + x] = UInt8(min(magnitude / 256.0, 1.0) * 255)
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: &rawData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }

        // 中心線の描画
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(1)
        context.beginPath()
        context.move(to: CGPoint(x: width / 2, y: 0))
        context.addLine(to: CGPoint(x: width / 2, y: height))
        context.move(to: CGPoint(x: 0, y: height / 2))
        context.addLine(to: CGPoint(x: width, y: height / 2))
        context.strokePath()

        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }


    // UIImageを受け取ってFFTを実行し、結果をUIImageとして返す
    static func fftImage(_ inputImage: UIImage) -> UIImage? {
        let power2img = cropToPowerOfTwo(image: inputImage)
        let grayscaleImage = convertToGrayscale(image: power2img)
        guard var complexData = getGrayscalePixels(from: grayscaleImage) else { return nil }
        fft2(&complexData)
        return imageFromFFTResult(complexData)
    }
        
    // FFT 1d smearingとグレースケール画像を返す関数
    static func fftGraph(_ inputImage: UIImage) -> FFTResult? {
        let power2img = cropToPowerOfTwo(image: inputImage)
        let grayscaleImage = convertToGrayscale(image: power2img)
        guard var complexData = getGrayscalePixels(from: grayscaleImage) else { return nil }
        fft2(&complexData)
        let (distances, intensities) = averageIntensityByDistance(fftData: complexData)
        let filteredDistances = Array(distances.dropFirst())
        let filteredIntensities = Array(intensities.dropFirst())
        let dataPoints = zip(filteredDistances, filteredIntensities)
            .map(IntensityDataPoint.init)
        let intensityChartView = IntensityChartView(dataPoints: dataPoints)
        
        // グレースケール画像とグラフビューをタプルで返す
        return (grayscale: grayscaleImage, chartView: intensityChartView)
    }

}

// FFT処理結果とグレースケール画像を含むタプルを定義
typealias FFTResult = (grayscale: UIImage, chartView: IntensityChartView?)

struct IntensityChartView: View {
    var dataPoints: [IntensityDataPoint]

    var body: some View {
        Chart(dataPoints) {
            LineMark(
                x: .value("Distance", $0.distance),
                y: .value("log(Intensity)", $0.intensity)
            )
        }.padding(.all, 20) // ビューの周りにパディングを追加
        .chartXAxis {
            AxisMarks(preset: .automatic, 
                      position: .bottom,
                      values: .automatic)
        }
        .chartYAxis {
            AxisMarks(preset: .automatic, 
                      position: .leading,
                      values: .automatic)
        }
        .chartYScale(domain: .automatic(includesZero: true)) // Y軸のスケールを自動調整し、ゼロを含める
    }
}

struct IntensityDataPoint: Identifiable {
    let id = UUID() // 一意の識別子
    var distance: Double
    var intensity: Double
}
