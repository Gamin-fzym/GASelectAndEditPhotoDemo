//
//  MovEncodeToMpegTool.m
//  TZImagePickerControllerDemo
//
//  Created by 徐小龙 on 2019/11/11.
//  Copyright © 2019 Liyn. All rights reserved.
//

#pragma mark - WeakSelf/StrongSelf

#import <Photos/Photos.h>
#import "MovEncodeToMpegTool.h"

@implementation MovEncodeToMpegTool

/// 转码 MOV--MP4
/// @param resourceAsset MOV资源
/// @param exportQuality 预设
/// @param movEncodeToMpegToolResultBlock 转码后的MP4文件链接
+ (void)convertMovToMp4FromPHAsset:(PHAsset*)resourceAsset
     andAVAssetExportPresetQuality:(ExportPresetQuality)exportQuality
 andMovEncodeToMpegToolResultBlock:(MovEncodeToMpegToolResultBlock)movEncodeToMpegToolResultBlock {
    
    /*
     iOS 13 以前
     {
     assetLocalIdentifier = "A99AA1C3-7D59-4E10-A8D3-BF4FAD7A1BC6/L0/001";
     fileSize = 2212572;
     filename = "IMG_0049.MOV";
     size = "1080,1920";
     type = video;
     uti = "com.apple.quicktime-movie";
     }
     iOS 13
     {
     asset = "9B3F7172-14BB-462E-B003-1CDA5583B038/L0/001";
     duration = "20.678";
     filename = "IMG_0031.MOV";
     size = "1080,1920";
     type = video;
     uti = "com.apple.quicktime-movie";
     }
     */
    NSDictionary *videoInfo = [self getVideoInfo:resourceAsset];
    NSLog(@"\n%@", videoInfo);

    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = true;

    PHImageManager *manager = [PHImageManager defaultManager];
    [manager requestAVAssetForVideo:resourceAsset
                            options:options
                      resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;
            [MovEncodeToMpegTool convertMovToMp4FromAVURLAsset:urlAsset
                                 andAVAssetExportPresetQuality:exportQuality
                             andMovEncodeToMpegToolResultBlock:movEncodeToMpegToolResultBlock];
        } else {
            NSError *error = [NSError errorWithDomain:@"ConvertMovToMp4ErrorDomain"
                                                 code:10008
                                             userInfo:@{NSLocalizedDescriptionKey:@"resource type error"}];
            movEncodeToMpegToolResultBlock(nil, nil , error);
        }
    }];;
}

#pragma mark ### MOV转码MP4

+ (void)convertMovToMp4FromAVURLAsset:(AVURLAsset*)urlAsset
        andAVAssetExportPresetQuality:(ExportPresetQuality)exportQuality
    andMovEncodeToMpegToolResultBlock:(MovEncodeToMpegToolResultBlock)movEncodeToMpegToolResultBlock {
    
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:urlAsset.URL options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    // 查询是否有匹配的预设
    if ([compatiblePresets containsObject:[self getAVAssetExportPresetQuality:exportQuality]]) {
        //  在Documents目录下创建一个名为FileData的文件夹
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:@"Cache/VideoData"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
        if(!(isDirExist && isDir)) {
            BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            if(!bCreateDir){
                NSLog(@"创建文件夹失败！%@",path);
            }
            NSLog(@"创建文件夹成功，文件路径%@",path);
        }
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
        [formatter setDateFormat:@"yyyyMMddHHmmss"]; //每次启动后都保存一个新的文件中
        NSString *dateStr = [formatter stringFromDate:[NSDate date]];
        
        NSString *resultPath = [path stringByAppendingFormat:@"/%@.mp4",dateStr];
        NSLog(@"resultFileName = %@",dateStr);

        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset
                                                                               presetName:[self getAVAssetExportPresetQuality:exportQuality]];
        exportSession.outputURL = [NSURL fileURLWithPath:resultPath];
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
            switch (exportSession.status) {
                case AVAssetExportSessionStatusUnknown: {
                    NSError *error = [NSError errorWithDomain:@"ConvertMovToMp4ErrorDomain"
                                                         code:10001
                                                     userInfo:@{NSLocalizedDescriptionKey:@"AVAssetExportSessionStatusUnknown"}];
                    movEncodeToMpegToolResultBlock(nil, nil , error);
                }
                    break;
                case AVAssetExportSessionStatusWaiting: {
                    NSError *error = [NSError errorWithDomain:@"ConvertMovToMp4ErrorDomain"
                                                         code:10002
                                                     userInfo:@{NSLocalizedDescriptionKey:@"AVAssetExportSessionStatusWaiting"}];
                    movEncodeToMpegToolResultBlock(nil, nil , error);
                }
                    break;
                case AVAssetExportSessionStatusExporting: {
                    NSError *error = [NSError errorWithDomain:@"ConvertMovToMp4ErrorDomain"
                                                         code:10003
                                                     userInfo:@{NSLocalizedDescriptionKey:@"AVAssetExportSessionStatusExporting"}];
                    movEncodeToMpegToolResultBlock(nil, nil , error);
                }
                    break;
                case AVAssetExportSessionStatusCompleted: {
                    NSData *mp4Data = [NSData dataWithContentsOfURL:exportSession.outputURL];
                    movEncodeToMpegToolResultBlock(exportSession.outputURL, mp4Data , nil);
                }
                    break;
                case AVAssetExportSessionStatusFailed: {
                    NSError *error = [NSError errorWithDomain:@"ConvertMovToMp4ErrorDomain"
                                                         code:10005
                                                     userInfo:@{NSLocalizedDescriptionKey:@"AVAssetExportSessionStatusFailed"}];
                    movEncodeToMpegToolResultBlock(nil, nil , error);
                }
                    break;
                case AVAssetExportSessionStatusCancelled: {
                    NSError *error = [NSError errorWithDomain:@"ConvertMovToMp4ErrorDomain"
                                                         code:10006
                                                     userInfo:@{NSLocalizedDescriptionKey:@"AVAssetExportSessionStatusCancelled"}];
                    movEncodeToMpegToolResultBlock(nil, nil , error);
                }
                    break;
            }
        }];
    } else {
        NSError *error = [NSError errorWithDomain:@"ConvertMovToMp4ErrorDomain"
                                             code:10007
                                         userInfo:@{NSLocalizedDescriptionKey:@"AVAssetExportSessionStatusNoPreset"}];
        movEncodeToMpegToolResultBlock(nil, nil , error);
    }
}

/*
AVAssetExportPresetLowQuality        低质量 可以通过移动网络分享
AVAssetExportPresetMediumQuality     中等质量 可以通过WIFI网络分享
AVAssetExportPresetHighestQuality    高等质量
AVAssetExportPreset640x480
AVAssetExportPreset960x540
AVAssetExportPreset1280x720    720pHD
AVAssetExportPreset1920x1080   1080pHD
AVAssetExportPreset3840x2160
*/

+ (NSString *const )getAVAssetExportPresetQuality:(ExportPresetQuality)exportPreset {
    switch (exportPreset) {
        case ExportPresetLowQuality:
            return AVAssetExportPresetLowQuality;
        case ExportPresetMediumQuality:
            return AVAssetExportPresetMediumQuality;
        case ExportPresetHighestQuality:
            return AVAssetExportPresetHighestQuality;
        case ExportPreset640x480:
            return AVAssetExportPreset640x480;
        case ExportPreset960x540:
            return AVAssetExportPreset960x540;
        case ExportPreset1280x720:
            return AVAssetExportPreset1280x720;
        case ExportPreset1920x1080:
            return AVAssetExportPreset1920x1080;
        case ExportPreset3840x2160:
            return AVAssetExportPreset3840x2160;
    }
}

/// 收到转码结束回调
/// @param urlAsset 转码源文件
/// @param audioMix 转码源文件音频
/// @param vedioInfo 视频信息
/// @param size 视频文件大小
+ (void)choseVedioCompeletWithVedioAsset:(AVURLAsset *)urlAsset
                           andAVAudioMix:(AVAudioMix *)audioMix
                            andVedioInfo:(NSDictionary *)vedioInfo
                            andImageSize:(CGSize)size
           andAVAssetExportPresetQuality:(ExportPresetQuality)exportQuality
       andMovEncodeToMpegToolResultBlock:(MovEncodeToMpegToolResultBlock)movEncodeToMpegToolResultBlock {
    //[self showLoadingView:@"处理视频数据"];
}


+ (NSDictionary *)getVideoInfo:(PHAsset *)asset {
    // <PHAsset: 0x141d68b70> A99AA1C3-7D59-4E10-A8D3-BF4FAD7A1BC6/L0/001 mediaType=2/0, sourceType=1, (1080x1920), creationDate=2018-06-04 09:32:53 +0000, location=1, hidden=0, favorite=0
    /// 包含该视频的基础信息
    PHAssetResource * resource = [[PHAssetResource assetResourcesForAsset: asset] firstObject];
    NSMutableArray *resourceArray = nil;
    
    if (@available(iOS 13.0, *)) {
        NSString *string1 = [resource.description stringByReplacingOccurrencesOfString:@" - " withString:@" "];
        NSString *string2 = [string1 stringByReplacingOccurrencesOfString:@": " withString:@"="];
        NSString *string3 = [string2 stringByReplacingOccurrencesOfString:@"{" withString:@""];
        NSString *string4 = [string3 stringByReplacingOccurrencesOfString:@"}" withString:@""];
        NSString *string5 = [string4 stringByReplacingOccurrencesOfString:@", " withString:@" "];
        resourceArray = [NSMutableArray arrayWithArray:[string5 componentsSeparatedByString:@" "]];
        [resourceArray removeObjectAtIndex:0];
        [resourceArray removeObjectAtIndex:0];
    } else {
        NSString *string1 = [resource.description stringByReplacingOccurrencesOfString:@"{" withString:@""];
        NSString *string2 = [string1 stringByReplacingOccurrencesOfString:@"}" withString:@""];
        NSString *string3 = [string2 stringByReplacingOccurrencesOfString:@", " withString:@","];
        resourceArray = [NSMutableArray arrayWithArray:[string3 componentsSeparatedByString:@" "]];
        [resourceArray removeObjectAtIndex:0];
        [resourceArray removeObjectAtIndex:0];
    }
    
    NSMutableDictionary *videoInfo = [[NSMutableDictionary alloc] init];
    for (NSString *string in resourceArray) {
        NSArray *array = [string componentsSeparatedByString:@"="];
        if (array.count >= 2) {
            videoInfo[array[0]] = array[1];
        }
    }
    videoInfo[@"duration"] = @(asset.duration).description;
    return videoInfo;
}

@end
