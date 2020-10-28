//
//  HXEditObjectViewController.h
//  甲丁
//
//  Created by Gamin on 7/15/20.
//  Copyright © 2020 langdaoTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoModel.h"
#import "HXPhotoManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface HXEditObjectViewController : UIViewController

@property (strong, nonatomic) HXPhotoManager *manager;
@property (copy, nonatomic) void (^ReturnViewBlock)(NSArray<HXPhotoModel *> *edit_allList, NSArray<HXPhotoModel *> *edit_photoList, NSArray<HXPhotoModel *> *edit_videoList);
@property (copy, nonatomic) void (^EditImageCompleteBlock)(NSArray<HXPhotoModel *> *edit_allList, NSArray<HXPhotoModel *> *edit_photoList, NSArray<HXPhotoModel *> *edit_videoList);

- (void)setupDataWithAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original;

@end

NS_ASSUME_NONNULL_END
