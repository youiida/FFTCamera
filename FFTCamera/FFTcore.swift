//
//  FFTcore.swift
//  FFTCamera
//
//  Created by 飯田優羽 on 2024/01/30.
//

import UIKit
import Accelerate

func perform2DFFT(on image: UIImage) -> UIImage? {
    guard let cgImage = image.cgImage else { return nil }

    let width = cgImage.width
    let height = cgImage.height

    // ピクセルデータの取得とグレースケール変換
    guard let grayscaleBuffer = cgImage.toGrayscaleBuffer() else { return nil }

    var realp = [Float](repeating: 0, count: width * height)
    var imagp = [Float](repeating: 0, count: width * height)

    // ピクセルデータを実数配列に変換
    for row in 0..<height {
        for col in 0..<width {
            realp[row * width + col] = Float(grayscaleBuffer[row * width + col]) / 255.0
        }
    }

    // FFTの実行
    var forwardDFT = vDSP_DFT_zop_CreateSetup(nil,
                                              vDSP_Length(max(width, height)),
                                              .FORWARD)!
    
    var splitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)
    vDSP_fft2d_zip(forwardDFT, &splitComplex, 1, 0, vDSP_Length(log2(Float(width))), vDSP_Length(log2(Float(height))), FFTDirection(kFFTDirection_Forward))

    vDSP_DFT_DestroySetup(forwardDFT)

    // FFTの結果を画像として表示
    return spectrumImage(from: realp, width: width, height: height)
}

extension CGImage {
    func toGrayscaleBuffer() -> [UInt8]? {
        let width = self.width
        let height = self.height
        let bytesPerRow = width
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let colorSpace = CGColorSpaceCreateDeviceGray()

        var buffer = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(data: &buffer,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }
}


func amplitudeSpectrum(real: [Float], imaginary: [Float]) -> [Float] {
    let n = real.count
    var amplitude = [Float](repeating: 0, count: n)

    for i in 0..<n {
        amplitude[i] = sqrt(real[i] * real[i] + imaginary[i] * imaginary[i])
    }

    return amplitude
}

func spectrumImage(from amplitude: [Float], width: Int, height: Int) -> UIImage? {
    let logAmplitude = amplitude.map { log($0 + 1) } // 対数スケールに変換
    let normalizedAmplitude = normalize(logAmplitude)
    let image = imageFromAmplitude(normalizedAmplitude, width: width, height: height)
    return image
}

func normalize(_ values: [Float]) -> [UInt8] {
    guard let maxAmplitude = values.max() else { return [] }
    return values.map { UInt8($0 / maxAmplitude * 255) }
}

func imageFromAmplitude(_ amplitude: [UInt8], width: Int, height: Int) -> UIImage? {
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
    context?.data?.copyMemory(from: amplitude, byteCount: amplitude.count)

    if let cgImage = context?.makeImage() {
        return UIImage(cgImage: cgImage)
    } else {
        return nil
    }
}
