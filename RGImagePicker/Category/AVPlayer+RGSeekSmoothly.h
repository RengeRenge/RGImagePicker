//
//  AVPlayer+RGSeekSmoothly.h
//  CampTalk
//
//  Created by renge on 2019/9/4.
//  Copyright © 2019 yuru. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVPlayer(RGSeekSmoothly)

- (void)rg_seekToTime:(CMTime)time;

- (void)rg_seekToTime:(CMTime)time
      toleranceBefore:(CMTime)toleranceBefore
       toleranceAfter:(CMTime)toleranceAfter
    completionHandler:(void (^_Nullable)(BOOL))completionHandler;

@end

NS_ASSUME_NONNULL_END
