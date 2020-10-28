//
//  MovEncodeToMpegTool.h
//  TZImagePickerControllerDemo
//
//  Created by 徐小龙 on 2019/11/11.
//  Copyright © 2019 Liyn. All rights reserved.
//

@class PHAsset;
typedef void(^MovEncodeToMpegToolResultBlock)(NSURL *mp4FileUrl, NSData *mp4Data, NSError *error);

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    ExportPresetLowQuality,        //低质量 可以通过移动网络分享
    ExportPresetMediumQuality,     //中等质量 可以通过WIFI网络分享
    ExportPresetHighestQuality,    //高等质量
    ExportPreset640x480,
    ExportPreset960x540,
    ExportPreset1280x720,    //720pHD
    ExportPreset1920x1080,   //1080pHD
    ExportPreset3840x2160,
} ExportPresetQuality;

@interface MovEncodeToMpegTool : NSObject

/// 转码 MOV--MP4
/// @param resourceAsset MOV资源
/// @param exportQuality 预设
/// @param movEncodeToMpegToolResultBlock 转码后的MP4文件链接
+ (void)convertMovToMp4FromPHAsset:(PHAsset*)resourceAsset
     andAVAssetExportPresetQuality:(ExportPresetQuality)exportQuality
 andMovEncodeToMpegToolResultBlock:(MovEncodeToMpegToolResultBlock)movEncodeToMpegToolResultBlock;

@end


