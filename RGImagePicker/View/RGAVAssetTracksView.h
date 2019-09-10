//
//  RGAVPlayerItemTracks.h
//  CampTalk
//
//  Created by renge on 2019/9/4.
//  Copyright © 2019 yuru. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RGAVAssetTracksView : UIControl

@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, assign) CMTime time;

+ (RGAVAssetTracksView *)viewWithAVAsset:(AVAsset *)asset;

@end

NS_ASSUME_NONNULL_END
