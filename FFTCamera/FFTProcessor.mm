//
//  FFTProcessor.mm
//  FFTCamera
//
//  Created by 飯田優羽 on 2024/02/01.
//

// FFTProcessor.mm
#import "FFTProcessor.h"
#import <opencv2/opencv.hpp>

@implementation FFTProcessor

+ (UIImage *)fftImage:(UIImage *)image {
    cv::Mat mat;
    UIImageToMat(image, mat);
    cv::cvtColor(mat, mat, cv::COLOR_RGBA2GRAY);

    int m = cv::getOptimalDFTSize(mat.rows);
    int n = cv::getOptimalDFTSize(mat.cols);

    cv::Mat padded;
    cv::copyMakeBorder(mat, padded, 0, m - mat.rows, 0, n - mat.cols, cv::BORDER_CONSTANT, cv::Scalar::all(0));

    cv::Mat planes[] = {cv::Mat_<float>(padded), cv::Mat::zeros(padded.size(), CV_32F)};
    cv::Mat complexI;
    cv::merge(planes, 2, complexI);

    cv::dft(complexI, complexI);

    // 結果の振幅を計算
    cv::split(complexI, planes);
    cv::magnitude(planes[0], planes[1], planes[0]);
    cv::Mat magI = planes[0];

    // スペクトルのシフト
    magI = magI(cv::Rect(0, 0, magI.cols & -2, magI.rows & -2));
    int cx = magI.cols / 2;
    int cy = magI.rows / 2;

    cv::Mat q0(magI, cv::Rect(0, 0, cx, cy));
    cv::Mat q1(magI, cv::Rect(cx, 0, cx, cy));
    cv::Mat q2(magI, cv::Rect(0, cy, cx, cy));
    cv::Mat q3(magI, cv::Rect(cx, cy, cx, cy));

    cv::Mat tmp;
    q0.copyTo(tmp);
    q3.copyTo(q0);
    tmp.copyTo(q3);

    q1.copyTo(tmp);
    q2.copyTo(q1);
    tmp.copyTo(q2);

    // 振幅のスケーリングと変換
    cv::normalize(magI, magI, 0, 1, cv::NORM_MINMAX);
    magI += cv::Scalar::all(1);
    cv::log(magI, magI);

    // 振幅を正規化
    cv::normalize(magI, magI, 0, 255, cv::NORM_MINMAX);

    cv::Mat_<uchar> output;
    magI.convertTo(output, CV_8U);
    return MatToUIImage(output);
}

@end
