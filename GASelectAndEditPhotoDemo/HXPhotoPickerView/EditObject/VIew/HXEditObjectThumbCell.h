//
//  HXEditObjectThumbCell.h
//  甲丁
//
//  Created by Gamin on 2020/7/15.
//  Copyright © 2020 langdaoTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HXEditObjectThumbCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbIV;
@property (weak, nonatomic) IBOutlet UIButton *statusBut;
@property (weak, nonatomic) IBOutlet UIImageView *videoMarkIV;
@property (weak, nonatomic) HXPhotoModel *dataModel;

- (void)initWithObject:(id)object IndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
