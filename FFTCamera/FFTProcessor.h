//
//  ImageProcessor.h
//  FFTCamera
//
//  Created by 飯田優羽 on 2024/02/01.
//

#ifndef FFTProcessor_h
#define FFTProcessor_h

// FFTProcessor.h
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FFTProcessor : NSObject

+ (UIImage *)fftImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END


#endif /* FFTProcessor_h */
