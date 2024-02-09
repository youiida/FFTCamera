//
//  FFTcore.swift
//  FFTCamera
//
//  Created by 飯田優羽 on 2024/01/30.
//

import UIKit
import Accelerate
import Foundation

struct Complex {
    var real: Double
    var imag: Double

    init(_ real: Double, _ imag: Double) {
        self.real = real
        self.imag = imag
    }

    func magnitude() -> Double {
        return sqrt(real * real + imag * imag)
    }
}

func +(lhs: Complex, rhs: Complex) -> Complex {
    return Complex(lhs.real + rhs.real, lhs.imag + rhs.imag)
}

func -(lhs: Complex, rhs: Complex) -> Complex {
    return Complex(lhs.real - rhs.real, lhs.imag - rhs.imag)
}

func *(lhs: Complex, rhs: Complex) -> Complex {
    return Complex(lhs.real * rhs.real - lhs.imag * rhs.imag, lhs.real * rhs.imag + lhs.imag * rhs.real)
}

func /(lhs: Complex, rhs: Double) -> Complex {
    return Complex(lhs.real / rhs, lhs.imag / rhs)
}

func polar(_ r: Double, _ theta: Double) -> Complex {
    return Complex(r * cos(theta), r * sin(theta))
}

func fft(_ x: inout [Complex]) {
    let N = x.count
    if N <= 1 { return }

    var even = [Complex](repeating: Complex(0, 0), count: N/2)
    var odd = [Complex](repeating: Complex(0, 0), count: N/2)

    for i in 0..<(N/2) {
        even[i] = x[i*2]
        odd[i] = x[i*2 + 1]
    }

    fft(&even)
    fft(&odd)

    for k in 0..<(N/2) {
        let t = polar(1.0, -2 * Double.pi * Double(k) / Double(N)) * odd[k]
        x[k] = even[k] + t
        x[k + N/2] = even[k] - t
    }
}

func fft2(_ x: inout [[Complex]]) {
    for i in 0..<x.count {
        fft(&x[i])
    }

    let cols = x[0].count
    for i in 0..<cols {
        var col = [Complex](repeating: Complex(0, 0), count: x.count)
        for j in 0..<x.count {
            col[j] = x[j][i]
        }

        fft(&col)

        for j in 0..<x.count {
            x[j][i] = col[j]
        }
    }
    fftShift(&x)
}

func fftShift(_ x: inout [[Complex]]) {
    let M = x.count
    let N = x[0].count
    let halfM = M / 2
    let halfN = N / 2

    for i in 0..<halfM {
        for j in 0..<halfN {
            // 一時変数を使用して値を交換
            let temp = x[i][j]
            x[i][j] = x[i + halfM][j + halfN]
            x[i + halfM][j + halfN] = temp
            
            let temp2 = x[i + halfM][j]
            x[i + halfM][j] = x[i][j + halfN]
            x[i][j + halfN] = temp2
        }
    }

    // 奇数のサイズの場合、中心行と中心列を適切にシフトする
    if M % 2 == 1 {
        for j in 0..<halfN {
            let temp = x[halfM][j]
            x[halfM][j] = x[halfM][j + halfN]
            x[halfM][j + halfN] = temp
        }
    }
    if N % 2 == 1 {
        for i in 0..<halfM {
            let temp = x[i][halfN]
            x[i][halfN] = x[i + halfM][halfN]
            x[i + halfM][halfN] = temp
        }
    }
}


func averageIntensityByDistance(fftData: [[Complex]]) -> (distances: [Double], intensities: [Double]) {
    let height = fftData.count
    let width = fftData[0].count
    let centerX = Double(width) / 2.0
    let centerY = Double(height) / 2.0
    let maxDistance = min(centerX, centerY) // 中心からの最大距離
    var intensityDict = [Double: (totalIntensity: Double, count: Double)]()

    for y in 0..<height {
        for x in 0..<width {
            let distance = sqrt(pow(Double(x) - centerX, 2) + pow(Double(y) - centerY, 2))
            if distance <= maxDistance { // 中心からの最大距離内のデータのみを使用
                let magnitude = fftData[y][x].magnitude()
                let logIntensity = log(magnitude + 1) // 対数を取る（オフセットを加えて負の無限大を避ける）

                if intensityDict[distance] == nil {
                    intensityDict[distance] = (totalIntensity: logIntensity, count: 1)
                } else {
                    intensityDict[distance]?.totalIntensity += logIntensity
                    intensityDict[distance]?.count += 1
                }
            }
        }
    }

    var distances: [Double] = []
    var intensities: [Double] = []

    for (distance, data) in intensityDict {
        distances.append(distance)
        intensities.append(data.totalIntensity / data.count)
    }

    // 距離に基づいてソート
    let sortedIndices = distances.enumerated().sorted(by: {$0.element < $1.element}).map({$0.offset})
    distances = sortedIndices.map { distances[$0] }
    intensities = sortedIndices.map { intensities[$0] }
    // 最初の要素を捨てる
    distances = Array(distances.dropFirst())
    intensities = Array(intensities.dropFirst())
    return (distances, intensities)
}

