//
//  HXEditObjectThumbCell.m
//  甲丁
//
//  Created by Gamin on 2020/7/15.
//  Copyright © 2020 langdaoTech. All rights reserved.
//

#import "HXEditObjectThumbCell.h"

@implementation HXEditObjectThumbCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)releaseAction {
    _thumbIV.image = nil;
    _statusBut.selected = NO;
    _videoMarkIV.hidden = YES;
}

- (void)initWithObject:(id)object IndexPath:(NSIndexPath *)indexPath {
    [self releaseAction];
    if (object) {
        _dataModel = (HXPhotoModel *)object;
        _thumbIV.image = _dataModel.thumbPhoto?:_dataModel.previewPhoto;
        if (_dataModel.haveEdit) {
            _statusBut.selected = YES;
        }
        if (_dataModel.type == HXPhotoModelMediaTypeVideo) {
            _videoMarkIV.hidden = NO;
        }
    }
}

@end
