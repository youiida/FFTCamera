//
//  ImageControl.swift
//  FFTCamera
//
//  Created by 飯田優羽 on 2024/01/30.
//

import Foundation
import UIKit
import opencv2

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func openCamera(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            print("Camera not available")
        }
    }

    @IBAction func openPhotoLibrary(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }

    // UIImagePickerControllerDelegateメソッド
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let selectedImage = info[.originalImage] as? UIImage {
            // 選択された画像を取得
            // ここで何かの処理を行う
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}




enum ImageProcessor {
    static func grayscale(image: UIImage?) -> UIImage? {
        guard let image = image else {
            return nil
        }
        
        let mat = Mat(uiImage: image)
        Imgproc.cvtColor(
            src: mat,
            dst: mat,
            code: ColorConversionCodes.COLOR_RGB2GRAY
        )
        return mat.toUIImage()
    }
}
/*
    // FFTを実行する関数
    static func fft(image: UIImage?) -> UIImage? {
        guard let image = image else {
            return nil
        }

        let mat = Mat(uiImage: image)
        Imgproc.cvtColor(src: mat, 
                         dst: mat,
                         code: ColorConversionCodes.COLOR_RGBA2GRAY)

        let m = Core.getOptimalDFTSize(vecsize: mat.rows())
        let n = Core.getOptimalDFTSize(vecsize: mat.cols())

        let padded = Mat()
        Core.copyMakeBorder(src: mat, dst: padded, top: 0, bottom: m - mat.rows(), left: 0, right: n - mat.cols(), borderType: Core.BORDER_CONSTANT, value: Scalar.all(0))

        var planes = [padded, Mat.zeros(padded.size(), type: CvType.CV_32F)]
        let complexI = Mat()
        Core.merge(mv: planes, dst: complexI)

        Core.dft(src: complexI, dst: complexI)

        // 結果の振幅を計算
        Core.split(m: complexI, mv: &planes)
        Core.magnitude(x: planes[0], y: planes[1], magnitude: planes[0])
        let magI = planes[0]

        // スペクトルのシフト
        let cx = magI.cols() / 2
        let cy = magI.rows() / 2

        let q0 = Mat(mat: magI, 
                     rowRange: Range(start: 0, end: cy),
                     colRange: Range(start: 0, end: cx))
        let q1 = Mat(mat: magI, 
                     rowRange: Range(start: 0, end: cy),
                     colRange: Range(start: cx, end: magI.cols()))
        let q2 = Mat(mat: magI, 
                     rowRange: Range(start: cy, end: magI.rows()),
                     colRange: Range(start: 0, end: cx))
        let q3 = Mat(mat: magI, 
                     rowRange: Range(start: cy, end: magI.rows()),
                     colRange: Range(start: cx, end: magI.cols()))

        let tmp = Mat()
        q0.copy(to: tmp)
        q3.copy(to: q0)
        tmp.copy(to: q3)

        q1.copy(to: tmp)
        q2.copy(to: q1)
        tmp.copy(to: q2)

        // 振幅のスケーリングと変換
        Core.add(src1: Mat.ones(size: magI.size(),
                                type: CvType.CV_32F),
                src2: magI, dst: magI)  // 1を足すことで対数が0にならないようにする
        Core.log(src: magI, dst: magI)

        // 振幅を正規化
        Core.normalize(src: magI, 
                       dst: magI,
                       alpha: 0,
                       beta: 1,
                       norm_type: Core.NORM_MINMAX)

        return magI.toUIImage()
    }
}

*/
