//
//  IWCheckImageHaveFace.h
//  甲丁
//
//  Created by Gamin on 7/7/20.
//  Copyright © 2020 www.hidui.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IWCheckImageHaveFace : NSObject

+ (UIImage *)sampleBufferToImage:(CMSampleBufferRef)sampleBuffer;

/// 检测图片上是否有人脸
+ (BOOL)checkHaveFaceWithImage:(UIImage *)resultImage;

@end

NS_ASSUME_NONNULL_END
