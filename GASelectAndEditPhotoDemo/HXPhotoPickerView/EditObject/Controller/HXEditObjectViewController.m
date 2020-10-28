//
//  HXEditObjectViewController.m
//  甲丁
//
//  Created by Gamin on 7/15/20.
//  Copyright © 2020 langdaoTech. All rights reserved.
//

#import "HXEditObjectViewController.h"
#import "CommonHeader.h"
#import "GAPublicClass.h"
#import "HXPhotoViewController.h"
#import "HXPhotoPreviewViewController.h"
#import "HXEditObjectThumbCell.h"
//导入系统框架
#import <AVFoundation/AVFoundation.h>

@interface HXEditObjectViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topDevConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewWConstraint;
@property (weak, nonatomic) IBOutlet UICollectionView *previewCollectionView;
@property (weak, nonatomic) IBOutlet UIButton *rotationBut;
@property (weak, nonatomic) IBOutlet UIButton *resetBut;
@property (weak, nonatomic) IBOutlet UIView *bottomFunView;
@property (weak, nonatomic) IBOutlet UIView *playerBaseView;
@property (weak, nonatomic) IBOutlet UIButton *palyButton;
@property (weak, nonatomic) IBOutlet UILabel *numLab;
@property (weak, nonatomic) IBOutlet UIView *topFunView;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIScrollView *imageScrollView;
@property (strong, nonatomic) UIImageView *dealWithIV;
@property (strong, nonatomic) UIView *interceptionView;

@property (strong, nonatomic) NSArray<HXPhotoModel *> *save_allList;
@property (strong, nonatomic) NSArray<HXPhotoModel *> *save_photoList;
@property (strong, nonatomic) NSArray<HXPhotoModel *> *save_videoList;
@property (weak, nonatomic) HXPhotoModel *selectModel;

@property (strong, nonatomic) AVPlayer *avPlayer;

@end

@implementation HXEditObjectViewController

- (void)dealloc {
    [self removePlayerAction];
    self.avPlayer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (IS_IPHONE_X) {
        _topDevConstraint.constant = 44.0;
    } else {
        _topDevConstraint.constant = 20.0;
    }
    [GAPublicClass setButtonLocation:_rotationBut Mark:1];
    [GAPublicClass setButtonLocation:_resetBut Mark:1];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

// 设置scrollView和imageView的frame
- (void)adaptiveImageViewFrame {
    float sWith = [UIScreen mainScreen].bounds.size.width;
    float sHigh = [UIScreen mainScreen].bounds.size.height;
    
    [self.scrollView setContentSize:CGSizeMake(sWith, sHigh)];
    [self.imageScrollView setFrame:CGRectMake(0, 0, sWith, sHigh)];
    
    CGRect intRect = self.interceptionView.frame;
    UIImage *editImage = self.dealWithIV.image;
    if (editImage) {
        float imgWidth = editImage.size.width;
        float imgHeight = editImage.size.height;
        float nWidth = 0;
        float nHeight = 0;
        if (imgWidth < imgHeight) {
            nWidth = intRect.size.width;
            nHeight = (imgHeight/imgWidth)*nWidth;
        } else {
            nHeight = intRect.size.height;
            nWidth = (imgWidth/imgHeight)*nHeight;
        }

        CGRect ivRect = CGRectMake(CGRectGetMinX(intRect), CGRectGetMinY(intRect), nWidth, nHeight);
        [self.dealWithIV setFrame:ivRect];
        [self.imageScrollView setContentSize:CGSizeMake(CGRectGetMaxX(ivRect) + CGRectGetMinX(ivRect), CGRectGetMaxY(ivRect) + CGRectGetMinY(ivRect))];
    } else {
        [self.dealWithIV setFrame:intRect];
    }
}

- (BOOL)judgeModelIsVideo:(HXPhotoModel *)model {
    BOOL result = NO;
    if (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeCameraVideo) {
        result = YES;
    }
    return result;
}

- (void)updateSubViewFrame {
    [self removePlayerAction];

    self.dealWithIV.image = self.selectModel.previewPhoto?:self.selectModel.thumbPhoto;
    self.imageScrollView.zoomScale = 1;
    
    [self.view insertSubview:self.scrollView atIndex:0];
    [self.scrollView addSubview:self.imageScrollView];
    [self.imageScrollView addSubview:self.dealWithIV];
    [self setupInterceptionView];

    [self adaptiveImageViewFrame];
    if ([self judgeModelIsVideo:self.selectModel]) {
        // 视频不让编辑
        self.scrollView.hidden = YES;
        self.interceptionView.hidden = YES;
        self.bottomFunView.hidden = YES;
        self.playerBaseView.hidden = NO;
        [self repareAVPalerWithModel:self.selectModel];
    } else {
        self.scrollView.hidden = NO;
        self.interceptionView.hidden = NO;
        self.bottomFunView.hidden = NO;
        self.playerBaseView.hidden = YES;
    }
}

- (void)repareAVPalerWithModel:(HXPhotoModel *)videoModel {
    if (videoModel.videoURL) {
        [self setupAVPlayerWithPath:[videoModel.videoURL absoluteString] Asset:nil];
        return;
    }

    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;

    PHImageManager *manager = [PHImageManager defaultManager];
    [manager requestAVAssetForVideo:videoModel.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        AVURLAsset *urlAsset = (AVURLAsset *)asset;
        NSURL *url = urlAsset.URL; // file:///Users/susan/Library/Developer/CoreSimulator/Devices/3E31BF1A-AFF7-4141-B20D-9B17987E64F3/data/Media/DCIM/100APPLE/IMG_0030.MP4
        [self setupAVPlayerWithPath:@"" Asset:asset];
    }];
}

- (void)setupAVPlayerWithPath:(NSString *)path Asset:(AVAsset *)Asset {
    //设置播放的项目
    AVPlayerItem *item;
    if (!Asset) {
        //网络视频播放
        item = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:path]];
    } else {
        //本地视频播放
        item = [[AVPlayerItem alloc] initWithAsset:Asset];
    }
    //初始化player对象
    self.avPlayer = [[AVPlayer alloc] initWithPlayerItem:item];
    //设置播放页面
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_avPlayer];
    //设置播放页面的大小
    layer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    layer.backgroundColor = [UIColor blackColor].CGColor;
    //设置播放窗口和当前视图之间的比例显示内容
    //1.保持纵横比；适合层范围内
    //2.保持纵横比；填充层边界
    //3.拉伸填充层边界
    /*
    第1种AVLayerVideoGravityResizeAspect是按原视频比例显示，是竖屏的就显示出竖屏的，两边留黑；
    第2种AVLayerVideoGravityResizeAspectFill是以原比例拉伸视频，直到两边屏幕都占满，但视频内容有部分就被切割了；
    第3种AVLayerVideoGravityResize是拉伸视频内容达到边框占满，但不按原比例拉伸，这里明显可以看出宽度被拉伸了。
     */
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
    //添加播放视图到self.view
    dispatch_async(dispatch_get_main_queue(), ^{
        // 通知主线程刷新
        [self.playerBaseView.layer addSublayer:layer];
        [self.playerBaseView bringSubviewToFront:self.palyButton];
        [self.palyButton setImage:[UIImage imageNamed:@"bjbfPlay.png"] forState:UIControlStateNormal];
    });
    //视频播放
    //[self.avPlayer play];
    //视频暂停
    //[self.avPlayer pause];
}

// 视频循环播放
- (void)moviePlayDidEnd:(NSNotification *)notification {
    if (self.avPlayer) {
        AVPlayerItem *item = self.avPlayer.currentItem;
        [item seekToTime:kCMTimeZero];
        [self.avPlayer play];
    }
}

- (void)removePlayerAction {
    if (self.avPlayer) {
        [self.avPlayer pause];
    }
    [self.palyButton setImage:nil forState:UIControlStateNormal];
}

- (IBAction)tapPlayButtonAction:(id)sender {
    UIButton *tempBut = (UIButton *)sender;
    if (tempBut.currentImage) {
        [tempBut setImage:nil forState:UIControlStateNormal];
        if (self.avPlayer) {
            [self.avPlayer play];
        }
    } else {
        [tempBut setImage:[UIImage imageNamed:@"bjbfPlay.png"] forState:UIControlStateNormal];
        if (self.avPlayer) {
            [self.avPlayer pause];
        }
    }
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.backgroundColor = [UIColor clearColor];
        [_scrollView setShowsVerticalScrollIndicator:NO];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView.layer setMasksToBounds:YES];
        _scrollView.tag = 2300;
        _scrollView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        [GAPublicClass adaptationSafeAreaWith:_scrollView useArea:1];
    }
    return _scrollView;
}

- (UIScrollView *)imageScrollView {
    if (!_imageScrollView) {
        _imageScrollView = [[UIScrollView alloc] init];
        _imageScrollView.backgroundColor = [UIColor clearColor];
        [_imageScrollView setShowsVerticalScrollIndicator:NO];
        [_imageScrollView setShowsHorizontalScrollIndicator:NO];
        [_imageScrollView.layer setMasksToBounds:YES];
        _imageScrollView.delegate = self;
        _imageScrollView.maximumZoomScale = 3.0;
        _imageScrollView.minimumZoomScale = 1.0;
        [GAPublicClass adaptationSafeAreaWith:_imageScrollView useArea:1];
    }
    return _imageScrollView;
}

- (UIImageView *)dealWithIV {
    if (!_dealWithIV) {
        _dealWithIV = [[UIImageView alloc] init];
        _dealWithIV.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _dealWithIV;
}

// 添加截取框
- (void)setupInterceptionView {
    if (self.manager.configuration.customCameraType == HXPhotoCustomCameraTypeVideo) {
        return;
    }
    
    float w = [UIScreen mainScreen].bounds.size.width;
    float h = [UIScreen mainScreen].bounds.size.height;
    float bl = self.manager.configuration.interceptionProportion;
    float space = self.manager.configuration.interceptionSpacing;
    
    float jq_w = 0;
    float jq_h = 0;
    if (w < h) {
        jq_w = w - space*2;
        jq_h = jq_w / bl;
    } else {
        jq_h = h - space*2;
        jq_w = jq_h * bl;
    }
    
    if (!_interceptionView) {
        UIView *boundView = [[UIView alloc] init];
        boundView.backgroundColor = [UIColor clearColor];
        boundView.frame = CGRectMake(0, 0, jq_w, jq_h);
        boundView.userInteractionEnabled = NO;
        // [boundView.layer setBorderWidth:1];
        // [boundView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
        _interceptionView = boundView;
        // 线条
        float l_w = 34.0;
        float l_h = 4.0;
        for (int i = 0 ; i < 8 ; i ++) {
            UIView *line1 = [[UIView alloc] init];
            line1.backgroundColor = [UIColor whiteColor];
            [line1.layer setCornerRadius:l_h/2.0];
            [boundView addSubview:line1];
            if (i == 0) {
                line1.frame = CGRectMake(0, 0, l_w, l_h);
            } else if (i == 1) {
                line1.frame = CGRectMake(0, 0, l_h, l_w);
            } else if (i == 2) {
                line1.frame = CGRectMake(0, jq_h-l_h, l_w, l_h);
            } else if (i == 3) {
                line1.frame = CGRectMake(0, jq_h-l_w, l_h, l_w);
            } else if (i == 4) {
                line1.frame = CGRectMake(jq_w-l_w, 0, l_w, l_h);
            } else if (i == 5) {
                line1.frame = CGRectMake(jq_w-l_h, 0, l_h, l_w);
            } else if (i == 6) {
                line1.frame = CGRectMake(jq_w-l_w, jq_h-l_h, l_w, l_h);
            } else if (i == 7) {
                line1.frame = CGRectMake(jq_w-l_h, jq_h-l_w, l_h, l_w);
            }
        }
    }
    _interceptionView.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, [UIScreen mainScreen].bounds.size.height/2.0);
    [self.view addSubview:_interceptionView];
    [self setupInterceptionBackgroundView];
}

- (void)setupInterceptionBackgroundView {
    float w = [UIScreen mainScreen].bounds.size.width;
    float h = [UIScreen mainScreen].bounds.size.height;
    CGRect centerRect = _interceptionView.frame;
    
    UIView *leftBGView = [_interceptionView viewWithTag:8900];
    if (!leftBGView) {
        leftBGView = [[UIView alloc] init];
        leftBGView.tag = 8900;
        leftBGView.backgroundColor = [UIColor blackColor];
        leftBGView.alpha = 0.3;
    }
    leftBGView.frame = CGRectMake(-CGRectGetMinX(centerRect), -CGRectGetMinY(centerRect), CGRectGetMinX(centerRect), h);
    [_interceptionView addSubview:leftBGView];
    
    UIView *topBGView = [_interceptionView viewWithTag:8901];
    if (!topBGView) {
        topBGView = [[UIView alloc] init];
        topBGView.tag = 8901;
        topBGView.backgroundColor = [UIColor blackColor];
        topBGView.alpha = 0.3;
    }
    topBGView.frame = CGRectMake(0, -CGRectGetMinY(centerRect), CGRectGetWidth(centerRect), CGRectGetMinY(centerRect));
    [_interceptionView addSubview:topBGView];
    
    UIView *rightBGView = [_interceptionView viewWithTag:8902];
    if (!rightBGView) {
        rightBGView = [[UIView alloc] init];
        rightBGView.tag = 8902;
        rightBGView.backgroundColor = [UIColor blackColor];
        rightBGView.alpha = 0.3;
    }
    rightBGView.frame = CGRectMake(CGRectGetWidth(centerRect), -CGRectGetMinY(centerRect), w-CGRectGetMaxX(centerRect), h);
    [_interceptionView addSubview:rightBGView];
    
    UIView *bottonBGView = [_interceptionView viewWithTag:8903];
    if (!bottonBGView) {
        bottonBGView = [[UIView alloc] init];
        bottonBGView.tag = 8903;
        bottonBGView.backgroundColor = [UIColor blackColor];
        bottonBGView.alpha = 0.3;
    }
    bottonBGView.frame = CGRectMake(0, CGRectGetHeight(centerRect), CGRectGetWidth(centerRect), h-CGRectGetMaxY(centerRect));
    [_interceptionView addSubview:bottonBGView];
    
    [self.view bringSubviewToFront:_topFunView];
    [self.view bringSubviewToFront:_bottomFunView];
}

- (void)setupPreviewWidthWithCount:(NSInteger)count {
    if (count <= 1) {
        count = 1;
    }
    float w = [UIScreen mainScreen].bounds.size.width - 2*(50+8) - 2*8;
    float n_w = count*50 + (count-1)*15;
    dispatch_async(dispatch_get_main_queue(), ^{
       // 通知主线程刷新
       if (w < n_w) {
           _previewWConstraint.constant = w;
       } else {
           _previewWConstraint.constant = n_w;
       }
    });
}

// 返回
- (IBAction)goBackAction:(id)sender {
    [self removePlayerAction];
    if (self.ReturnViewBlock) {
        self.ReturnViewBlock(_save_allList, _save_photoList, _save_videoList);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 完成
- (IBAction)finishAction:(id)sender {
    [self removePlayerAction];
    BOOL result = YES;
    for (HXPhotoModel *model in _save_allList) {
        if (!model.haveEdit) {
            result = NO;
        }
    }
    if (!result) {
        [self.view hx_showImageHUDText:@"图片还未编辑完"];
        return;
    }
    
    if (self.EditImageCompleteBlock) {
        self.EditImageCompleteBlock(_save_allList, _save_photoList, _save_videoList);
    }
    [self dismissViewControllerAnimated:NO completion:nil];
    [[self topViewController] dismissViewControllerAnimated:NO completion:nil];
}

// 旋转
- (IBAction)tapRotationAction:(id)sender {
    [self reUpdateViewFrameWithImage:[_dealWithIV.image hx_rotationImage:UIImageOrientationLeft]];
}

// 重置
- (IBAction)tapResetAction:(id)sender {
    [self reUpdateViewFrameWithImage:self.selectModel.editOriginalPhoto];
}

- (void)reUpdateViewFrameWithImage:(UIImage *)newImage {
    UIImage *image = newImage;
    float bl = image.size.width/image.size.height;
    float intbl = self.manager.configuration.interceptionProportion;
    if (fabsf(bl-intbl) < 0.09) {
        self.selectModel.haveEdit = YES;
    } else {
        self.selectModel.haveEdit = NO;
    }
    if ([self judgeModelIsVideo:self.selectModel]) {
        // 视频不让编辑
        self.selectModel.haveEdit = YES;
    } else {
        
    }
    
    self.selectModel.previewPhoto = image;
    self.selectModel.thumbPhoto = image;
    [self.previewCollectionView reloadData];
    
    [self updateSubViewFrame];
}

// 完成编辑
- (IBAction)doneEditAction:(id)sender {
    float scale = self.imageScrollView.zoomScale;
    float offset_x = self.imageScrollView.contentOffset.x;
    float offset_y = self.imageScrollView.contentOffset.y;
    CGRect intRect = self.interceptionView.frame;
    CGRect imgRect = self.dealWithIV.frame;
    CGRect inImgRect = CGRectMake(intRect.origin.x+offset_x-imgRect.origin.x, intRect.origin.y+offset_y-imgRect.origin.y, intRect.size.width, intRect.size.height);
    UIImage *newImage = [GAPublicClass editImageWithOldImage:_dealWithIV.image OldFrame:imgRect CropFrame:inImgRect Scale:scale];
    
    [self reUpdateViewFrameWithImage:newImage];
}

- (UIViewController *)topViewController {
    UIViewController *resultVC;
    resultVC = [self _topViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _topViewController:resultVC.presentedViewController];
        if ([resultVC isKindOfClass:[HXPhotoViewController class]] || [resultVC isKindOfClass:[HXPhotoPreviewViewController class]]) {
            break;
        }
    }
    return resultVC;
}

- (UIViewController *)_topViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self _topViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self _topViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
    return nil;
}

- (void)setupDataWithAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    _save_allList = allList;
    _save_photoList = photoList;
    _save_videoList = videoList;
    for (int i = 0 ; i < _save_allList.count ; i ++) {
        HXPhotoModel *model = [_save_allList objectAtIndex:i];
        if (model.networkPhotoUrl?:model.networkThumbURL) { /// 是网络图片
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                // 处理耗时操作
                NSString *photoURLStr = [model.networkPhotoUrl?:model.networkThumbURL absoluteString];
                NSData *aa = [NSData dataWithContentsOfURL:[NSURL URLWithString:photoURLStr]];
                UIImage *image = [UIImage imageWithData:aa];
                [self setupModel:model Image:image Index:i];
//            });
        } else if (model.videoURL) { /// 是网络视频
//            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                // 处理耗时操作
                NSString *videoURLStr = [model.videoURL absoluteString];
                // https://lyzbjbx.oss-cn-hangzhou.aliyuncs.com/lyzblbs/client/2019/04/19/sc7ft5Zrqh.mp4?x-oss-process=video/snapshot,t_10000,m_fast
                if (![videoURLStr containsString:@"x-oss-process"]) {
                    videoURLStr = [NSString stringWithFormat:@"%@?x-oss-process=video/snapshot,t_10000,m_fast",videoURLStr];
                }
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:videoURLStr]]];
                [self setupModel:model Image:image Index:i];
//            });
        } else { /// 本地图片、视频
            [model requestPreviewImageWithSize:CGSizeMake(model.asset.pixelWidth, model.asset.pixelHeight) startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel * _Nullable model) {
                
            } progressHandler:^(double progress, HXPhotoModel * _Nullable model) {
                
            } success:^(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                model.editOriginalPhoto = image;
                model.previewPhoto = image;
                model.thumbPhoto = image;
                [self judgeHaveEditWitModel:model];
                if (i == 0) {
                    [self setupEditModel:model];
                }
                if (i == _save_allList.count-1) {
                    [_previewCollectionView reloadData];
                }
            } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
                if (i == _save_allList.count-1) {
                    [_previewCollectionView reloadData];
                }
            }];
        }
    }
    [self setupPreviewWidthWithCount:_save_allList.count?:0];
}

- (void)setupModel:(HXPhotoModel *)model Image:(UIImage *)image Index:(int)i {
    model.editOriginalPhoto = image;
    model.previewPhoto = image;
    model.thumbPhoto = image;
    [self judgeHaveEditWitModel:model];
    if (i == 0) {
        [self setupEditModel:model];
    }
    [self judgeReloadWithIndex:i];
}

- (void)judgeReloadWithIndex:(int)i {
    if (i == _save_allList.count-1) {
        [_previewCollectionView reloadData];
    }
}

- (void)judgeHaveEditWitModel:(HXPhotoModel *)model {
    if ([self judgeModelIsVideo:model]) {
        // 视频不让编辑
        model.haveEdit = YES;
        return;
    } else {
        
    }
    UIImage *image = model.previewPhoto?:model.thumbPhoto;;
    float bl = image.size.width/image.size.height;
    float intbl = self.manager.configuration.interceptionProportion;
    if (fabsf(bl-intbl) < 0.09) {
        model.haveEdit = YES;
        model.networkDontNeedEdit = YES;
    } else {
        model.haveEdit = NO;
    }
}

- (void)setupEditModel:(HXPhotoModel *)model {
    self.selectModel = model;
    dispatch_async(dispatch_get_main_queue(), ^{
       self.numLab.text = [NSString stringWithFormat:@"%d/%d",(int)([_save_allList indexOfObject:self.selectModel]+1) ,(int)_save_allList.count];
    });
    [self reUpdateViewFrameWithImage:self.selectModel.previewPhoto?:self.selectModel.thumbPhoto];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _save_allList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoModel *model;
    NSInteger index = indexPath.row;
    if (_save_allList.count > index) {
        model = [_save_allList objectAtIndex:index];
    }
    
    NSString *CellIdentifier = @"HXEditObjectThumbCell";
    UINib *cellNib = [UINib nibWithNibName:CellIdentifier bundle:nil];
    [collectionView registerNib:cellNib forCellWithReuseIdentifier:CellIdentifier];
    HXEditObjectThumbCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell initWithObject:model IndexPath:indexPath];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 3000) {
        HXEditObjectThumbCell *cell = (HXEditObjectThumbCell *)[collectionView cellForItemAtIndexPath:indexPath];
        HXPhotoModel *model = cell.dataModel;
        [self setupEditModel:model];
    } else {
        
    }
}

#pragma mark - UICollectionView设置Cell之间间距
// 定义每一个cell的大小
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 3000) {
        return (CGSize){50.0, 50.0};
    }
    return (CGSize){[UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height};
}

// 定义每个Section的四边间距
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (collectionView.tag == 3000) {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

// 两行cell之间的间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (collectionView.tag == 3000) {
        return 15;
    }
    return 0;
}

// 两列cell之间的间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if (collectionView.tag == 3000) {
        return 15;
    }
    return 0;
}

#pragma mark UIScrollViewDelegate
// 通过ScrollView的这个代理方法来实现图片的缩放
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView.tag != 2300) {
        /*
        NSArray *subViews = [scrollView subviews];
        UIImageView *imageView;
        for (int i = 0; i < subViews.count ; i ++) {
            UIView *tempView = [subViews objectAtIndex:i];
            if ([[tempView class] isSubclassOfClass:[UIImageView class]]) {
                imageView = (UIImageView *)tempView;
            }
        }
        return imageView;
         */
        return self.dealWithIV;
    } else {
        return nil;
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (scrollView.tag != 2300) {
        CGRect dd = self.dealWithIV.frame;
        [scrollView setContentSize:CGSizeMake(CGRectGetMaxX(dd) + CGRectGetMinX(dd), CGRectGetMaxY(dd) + CGRectGetMinY(dd))];
    }
}

@end
