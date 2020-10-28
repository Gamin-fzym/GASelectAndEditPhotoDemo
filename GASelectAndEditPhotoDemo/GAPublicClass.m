//
//  GAPublicClass.m
//  GASelectAndEditPhotoDemo
//
//  Created by Gamin on 10/27/20.
//  Copyright © 2020 MJKJ. All rights reserved.
//

#import "GAPublicClass.h"

@implementation GAPublicClass

/**
 * UIButton同时包含文字和图片时设置
 * mark = 0/1/2/3 表示图片分别在左/上/右/下
 * UIEdgeInsets insets = {top, left, bottom, right};
 * top    距可变区域顶部的距离
 * left   距可变区域左侧的距离
 * bottom 距可变区域底部的距离
 * right  距可变区域右侧的距离
 */
+ (void)setButtonLocation:(UIButton *)tempBut Mark:(NSInteger)mark {
    /*// 1.默认位置
    [tempBut setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [tempBut setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    // 2.居中位置
    [tempBut setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -tempBut.titleLabel.intrinsicContentSize.width)];
    [tempBut setTitleEdgeInsets:UIEdgeInsetsMake(0, -tempBut.currentImage.size.width, 0, 0)];*/
    // 3.需求位置
    float dev = 0.0;
    if (mark == 1) {
        // 图片在上
        [tempBut setImageEdgeInsets:UIEdgeInsetsMake(-tempBut.titleLabel.intrinsicContentSize.height - dev, 0, 0, -tempBut.titleLabel.intrinsicContentSize.width)];
        [tempBut setTitleEdgeInsets:UIEdgeInsetsMake(0, -tempBut.currentImage.size.width, -tempBut.currentImage.size.height - dev, 0)];
    } else if (mark == 2) {
        // 图片在右
        [tempBut setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -2*tempBut.titleLabel.intrinsicContentSize.width - dev)];
        [tempBut setTitleEdgeInsets:UIEdgeInsetsMake(0, -2*tempBut.currentImage.size.width - dev, 0, 0)];
    } else if (mark == 3) {
        // 图片在下
        [tempBut setImageEdgeInsets:UIEdgeInsetsMake(0, 0, -tempBut.titleLabel.intrinsicContentSize.height - dev, -tempBut.titleLabel.intrinsicContentSize.width)];
        [tempBut setTitleEdgeInsets:UIEdgeInsetsMake(-tempBut.currentImage.size.height - dev, -tempBut.currentImage.size.width, 0, 0)];
    } else {
        // 图片在左
        [tempBut setImageEdgeInsets:UIEdgeInsetsMake(0, 0 - dev, 0, 0)];
        [tempBut setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0 - dev)];
    }
}

/**
 * 适配iPhone X的安全区域
 * isUse = 1 表示使用安全区域
 * isUse = 0 表示不使用安全区域
 */
+ (void)adaptationSafeAreaWith:(UIScrollView *)sv useArea:(NSInteger)isUse {
    // 如果iOS的系统是11.0，不需要系统为你设置边缘距离
#ifdef __IPHONE_11_0
    if ([sv respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
        if (isUse) {
            if (@available(iOS 11.0, *)) {
                sv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
                if ([[sv class] isSubclassOfClass:[UITableView class]]) {
                    UITableView *tv = (UITableView *)sv;
                    [tv setInsetsContentViewsToSafeArea:NO];
                }
            } else {
                // Fallback on earlier versions
            }
        } else {
            if (@available(iOS 11.0, *)) {
                sv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
            } else {
                // Fallback on earlier versions
            }
        }
    }
#endif
}

/// 从UIView截图
+ (UIImage *)screenshotsFromView:(UIView *)shareView {
    // currentView 当前的view  创建一个基于位图的图形上下文并指定大小为
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(shareView.frame.size.width, shareView.frame.size.height), NO, 0.0);
    // renderInContext呈现接受者及其子范围到指定的上下文
    [shareView.layer renderInContext:UIGraphicsGetCurrentContext()];
    // 返回一个基于当前图形上下文的图片
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    // 移除栈顶的基于当前位图的图形上下文
    UIGraphicsEndImageContext();
    // 保存图片
    //UIImageWriteToSavedPhotosAlbum(viewImage, nil, nil, nil);
    return viewImage;
}

/// 截图 保证清晰度
+ (UIImage *)cropImageWithOldImage:(UIImage *)image OldFrame:(CGRect)oldFrame CropFrame:(CGRect)cropFrame {
    image = [self fixOrientation:image];
    
    float bs = 2;
    UIView *cropView = [[UIView alloc] initWithFrame:CGRectMake(cropFrame.origin.x*bs, cropFrame.origin.y*bs, cropFrame.size.width*bs, cropFrame.size.height*bs)]; // cropFrame
    cropView.backgroundColor = [UIColor clearColor];
    [cropView.layer setMasksToBounds:YES];
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithFrame:CGRectMake(-cropFrame.origin.x*bs, -cropFrame.origin.y*bs, oldFrame.size.width*bs, oldFrame.size.height*bs)];
    tempImageView.contentMode = UIViewContentModeScaleAspectFill;
    tempImageView.image = image;
    tempImageView.backgroundColor = [UIColor clearColor];
    [cropView addSubview:tempImageView];
    return [self screenshotsFromView:cropView];
}

/// 截图 保证清晰度
+ (UIImage *)editImageWithOldImage:(UIImage *)image OldFrame:(CGRect)oldFrame CropFrame:(CGRect)cropFrame Scale:(float)scale {
    image = [self fixOrientation:image];
    //(CGRect) imgRect = (origin = (x = 25, y = 243.5), size = (width = 325, height = 433.33334350585938))
    CGSize editSize = oldFrame.size;
    //(CGRect) inImgRect = (origin = (x = 0, y = 0), size = (width = 325, height = 325))
    CGSize imgSize = image.size;
    CGFloat widthScale;
    CGRect rct;
    if (imgSize.width < editSize.width) {
        widthScale = imgSize.width / editSize.width;
        rct = CGRectMake(cropFrame.origin.x*widthScale, cropFrame.origin.y*widthScale, cropFrame.size.width*widthScale, cropFrame.size.height*widthScale);
    } else {
        widthScale = editSize.width / imgSize.width;
        rct = CGRectMake(cropFrame.origin.x/widthScale, cropFrame.origin.y/widthScale, cropFrame.size.width/widthScale, cropFrame.size.height/widthScale);
    }
//    CGFloat heightScale = editSize.height / imgSize.height;
//    if (imgSize.height < editSize.height) {
//        heightScale = imgSize.height / editSize.height;
//    }
//    CGRect rct = CGRectMake(cropFrame.origin.x*widthScale, cropFrame.origin.y*widthScale, cropFrame.size.width*widthScale, cropFrame.size.height*heightScale);

    CGPoint origin = CGPointMake(-rct.origin.x, -rct.origin.y);
    UIImage *img = nil;
    UIGraphicsBeginImageContextWithOptions(rct.size, NO, image.scale);
    [image drawAtPoint:origin];
    img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return img;
}

/// 图片方向调整
+ (UIImage *)fixOrientation:(UIImage *)aImage {
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

// 使用系统提示
+ (void)useAlertAddVC:(UIViewController *)viewController Message:(NSString *)message {
    if (message == nil || [[message class] isSubclassOfClass:[NSNull class]]) {
        message = @"";
    }
    if ([message isEqualToString:@""]) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
