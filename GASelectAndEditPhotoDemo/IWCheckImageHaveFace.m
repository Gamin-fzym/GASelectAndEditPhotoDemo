//
//  IWCheckImageHaveFace.m
//  甲丁
//
//  Created by Gamin on 7/7/20.
//  Copyright © 2020 www.hidui.com. All rights reserved.
//

#import "IWCheckImageHaveFace.h"
#import "GAPublicClass.h"

//static CIDetector *detector = nil;

@interface IWCheckImageHaveFace ()


@end

@implementation IWCheckImageHaveFace

#pragma mark: lazyLoad
//+ (CIDetector *)detector {
//    if (!detector) {
//        detector = [CIDetector  detectorOfType:CIDetectorTypeFace context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh,CIDetectorMinFeatureSize:[[NSNumber alloc]initWithFloat:0.2],CIDetectorTracking:[NSNumber numberWithBool:YES]}];
//    }
//    return detector;
//}

+ (UIImage *)sampleBufferToImage:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))];
    UIImage *result = [[UIImage alloc] initWithCGImage:videoImage scale:1.0 orientation:UIImageOrientationLeftMirrored];
    CGImageRelease(videoImage);
    return result;
}

+ (BOOL)checkHaveFaceWithImage:(UIImage *)resultImage {
    BOOL result = NO;
    resultImage = [GAPublicClass fixOrientation:resultImage];
            
    CGFloat scale = [UIScreen mainScreen].bounds.size.width / resultImage.size.width;
    //CGFloat topMargin = ([UIScreen mainScreen].bounds.size.height - resultImage.size.height * scale) * 0.5;
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:resultImage];
    CIDetector *detector = [CIDetector  detectorOfType:CIDetectorTypeFace context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh,CIDetectorMinFeatureSize:[[NSNumber alloc] initWithFloat:0.2],CIDetectorTracking:[NSNumber numberWithBool:YES]}];
    NSArray<CIFaceFeature *> *results = (NSArray<CIFaceFeature *> *) [detector featuresInImage:ciImage options:@{CIDetectorImageOrientation:[[NSNumber alloc]initWithInt:1]}];
    
    if (results.count > 0) {
        result = YES;
    }
    return result;
}

@end
