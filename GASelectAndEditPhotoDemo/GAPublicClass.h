//
//  GAPublicClass.h
//  GASelectAndEditPhotoDemo
//
//  Created by Gamin on 10/27/20.
//  Copyright © 2020 MJKJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GAPublicClass : NSObject

/**
 * UIButton同时包含文字和图片时设置
 * mark = 0/1/2/3 表示图片分别在左/上/右/下
 * UIEdgeInsets insets = {top, left, bottom, right};
 * top    距可变区域顶部的距离
 * left   距可变区域左侧的距离
 * bottom 距可变区域底部的距离
 * right  距可变区域右侧的距离
 */
+ (void)setButtonLocation:(UIButton *)tempBut Mark:(NSInteger)mark;

/**
 * 适配iPhone X的安全区域
 * isUse = 1 表示使用安全区域
 * isUse = 0 表示不使用安全区域
 */
+ (void)adaptationSafeAreaWith:(UIScrollView *)sv useArea:(NSInteger)isUse;

/// 从UIView截图
+ (UIImage *)screenshotsFromView:(UIView *)shareView;

/// 截图 保证清晰度
+ (UIImage *)cropImageWithOldImage:(UIImage *)image OldFrame:(CGRect)oldFrame CropFrame:(CGRect)cropFrame;

/// 截图 保证清晰度
+ (UIImage *)editImageWithOldImage:(UIImage *)image OldFrame:(CGRect)oldFrame CropFrame:(CGRect)cropFrame Scale:(float)scale;

/// 图片方向调整
+ (UIImage *)fixOrientation:(UIImage *)aImage;

// 使用系统提示
+ (void)useAlertAddVC:(UIViewController *)viewController Message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
