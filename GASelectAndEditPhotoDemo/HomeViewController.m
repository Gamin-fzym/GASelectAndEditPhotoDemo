//
//  HomeViewController.m
//  GASelectAndEditPhotoDemo
//
//  Created by Gamin on 10/27/20.
//  Copyright © 2020 MJKJ. All rights reserved.
//

#import "HomeViewController.h"
#import "HXPhotoView.h"
#import "CommonHeader.h"
#import "MovEncodeToMpegTool.h"
#import "IWCheckImageHaveFace.h"
#import "GAPublicClass.h"

@interface HomeViewController () <HXPhotoViewDelegate>

@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (weak, nonatomic) IBOutlet UIImageView *didSelectImageView;

@end

@implementation HomeViewController

- (void)dealloc {
    _manager = nil;
    _photoView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"选择图片或视频";
}

- (IBAction)showSelectImageOrVideoAction:(id)sender {
    
}

- (IBAction)tapButtonAction:(id)sender {
    UIButton *tempBut = (UIButton *)sender;
    if (tempBut.tag == 680) {
        [self startTakePictureWithMark:0];
    } else if (tempBut.tag == 681) {
        [self startTakePictureWithMark:2];
    } else if (tempBut.tag == 682) {
        [self startTakePictureWithMark:3];
    }
}

#pragma mark --------------------------- 图片、视频上传 ---------------------------
#pragma mark - 开启摄像头拍照
// mark 0:图片 1:头像 2:视频 3:图片+视频
- (void)startTakePictureWithMark:(NSInteger)mark {
    NSString *tempTitle = @"选择";
    if (mark == 2) {
        tempTitle = @"拍摄和选择视频";
    } else if (mark == 3) {
        tempTitle = @"拍摄和选择图片和视频";
    } else {
        tempTitle = @"拍摄和选择图片";
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:tempTitle message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 跳转到相机
        [self setupSelectPhotoViewWithMark:mark];
        [self.photoView goCameraViewController];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"从相册中选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 跳转到相册页面
        [self setupSelectPhotoViewWithMark:mark];
        [self.photoView directGoPhotoViewController];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

- (void)setupSelectPhotoViewWithMark:(NSInteger)mark  {
    HXPhotoView *photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(800, 52, SCREENWIDTH - 30, 60) manager:[self setupManagerWithMark:mark]];
    photoView.delegate = self;
    photoView.outerCamera = YES;
    photoView.lineCount = 3;
    photoView.spacing = 16;

    photoView.backgroundColor = [UIColor whiteColor];
    photoView.hidden = YES;
    [self.view addSubview:photoView];
    self.photoView = photoView;
    if (mark == 0) {
        photoView.tag = 9800;
    } else if (mark == 1) {
        photoView.tag = 9801;
    } else if (mark == 2) {
        photoView.tag = 9802;
    } else {
        photoView.tag = 9803;
    }
}

- (HXPhotoManager *)setupManagerWithMark:(NSInteger)mark {
    HXPhotoManager *manager;
    if (mark == 2) {
        manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypeVideo];
    } else if (mark == 3) {
        manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
    } else {
        manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
    }
    manager.configuration.openCamera = NO;
    manager.configuration.lookLivePhoto = YES;
    manager.configuration.photoMaxNum = 1;//图片数量
    manager.configuration.videoMaxNum = 1;//视频最大数
    manager.configuration.maxNum = 1;//总数
    manager.configuration.videoMaximumDuration = 500.f;
    manager.configuration.saveSystemAblum = NO;//是否保存到相册
    manager.configuration.showDateSectionHeader = NO;
    manager.configuration.selectTogether = YES;//图片和照片是否同时选择
    // manager.configuration.requestImageAfterFinishingSelection = YES;
    manager.configuration.interceptionProportion = 3/4.0; // 截取的比例 默认1:1
    //manager.configuration.interceptionSpacing = 25.0; // 距边的间距 默认25
    self.manager = manager;
    return manager;
}

#pragma mark --- HXPhotoViewDelegate

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    [self uploadImages:photos andVidels:videos tag:photoView.tag];
}

/** 上传视频、图片 */
- (void)uploadImages:(NSArray *)photos andVidels:(NSArray *)videoArray tag:(NSInteger)tag {
    HXPhotoModel *imgModel = [photos firstObject];
    if (tag == 9801) {
        UIImage *editedImage = imgModel.previewPhoto?:imgModel.thumbPhoto;
        // 检测图片上是否有人脸
        if ([IWCheckImageHaveFace checkHaveFaceWithImage:editedImage]) {
            [self uploadImages:editedImage];
        } else {
            [GAPublicClass useAlertAddVC:self Message:@"使用的照片中不包含人脸，请重新选择"];
        }
    } else if (tag == 9802 || tag == 9803) {
        HXPhotoModel *videoModel = [videoArray firstObject];
        if (videoModel) {
            UIImage *editedImage = videoModel.previewPhoto?:videoModel.thumbPhoto;
            // 上传视频
            if (videoModel.videoURL) {
                [self uploadVideo:videoModel.videoURL Image:editedImage];
                return;
            }
            // 包含该视频的基础信息
            PHAssetResource * resource = [[PHAssetResource assetResourcesForAsset: videoModel.asset] firstObject];
            NSString * tempFilename = resource.originalFilename;
            NSArray * seArr = [tempFilename componentsSeparatedByString:@"."];
            if ([seArr.lastObject isEqualToString:@"mp4"] || [seArr.lastObject isEqualToString:@"MP4"]) {
                // 上传MP4
                PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
                options.version = PHImageRequestOptionsVersionCurrent;
                options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
                
                PHImageManager *manager = [PHImageManager defaultManager];
                [manager requestAVAssetForVideo:videoModel.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    AVURLAsset *urlAsset = (AVURLAsset *)asset;
                    NSURL *url = urlAsset.URL; // file:///Users/susan/Library/Developer/CoreSimulator/Devices/3E31BF1A-AFF7-4141-B20D-9B17987E64F3/data/Media/DCIM/100APPLE/IMG_0030.MP4
                    [self uploadVideo:url Image:editedImage];
                }];
            } else {
                // mov转mp4
                [MovEncodeToMpegTool convertMovToMp4FromPHAsset:videoModel.asset
                                  andAVAssetExportPresetQuality:ExportPresetMediumQuality
                              andMovEncodeToMpegToolResultBlock:^(NSURL *mp4FileUrl, NSData *mp4Data, NSError *error) {
                    [self uploadVideo:mp4FileUrl Image:editedImage];
                }];
            }
        } else {
            // 上传图片
            UIImage *editedImage = imgModel.previewPhoto?:imgModel.thumbPhoto;
            [self uploadImages:editedImage];
        }
    } else {
        UIImage *editedImage = imgModel.previewPhoto?:imgModel.thumbPhoto;
        [self uploadImages:editedImage];
    }
}

// 视频上传
- (void)uploadVideo:(NSURL *)videoPath Image:(UIImage *)editedImage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_didSelectImageView setImage:editedImage];
    });
}

// 图片上传
- (void)uploadImages:(UIImage *)editedImage {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_didSelectImageView setImage:editedImage];
    });
}

@end
