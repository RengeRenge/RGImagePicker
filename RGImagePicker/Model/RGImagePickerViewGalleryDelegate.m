//
//  RGImagePickerViewGalleryDelegate.m
//  CampTalk
//
//  Created by renge on 2019/9/5.
//  Copyright © 2019 yuru. All rights reserved.
//

#import "RGImagePickerViewGalleryDelegate.h"
#import "RGAVAssetTracksView.h"
#import "AVPlayer+RGSeekSmoothly.h"

@interface RGImagePickerViewGalleryDelegate ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) NSInteger loadIndex;
@property (nonatomic, assign) NSInteger reqVideoId;

@property (nonatomic, strong) RGAVAssetTracksView *tracks;

@property (nonatomic, strong) NSMutableArray <UIBarButtonItem *> *toolBarItem;
@property (nonatomic, strong) NSMutableArray <UIBarButtonItem *> *toolBarItemGallery;

@end

@implementation RGImagePickerViewGalleryDelegate

- (RGImagePickerConfig *)config {
    return self.cache.config;
}

- (NSArray <UIBarButtonItem *> *)toolBarItemForGallery:(BOOL)forGallery {
    BOOL isPlayingVideo = NO;
    if (forGallery) {
        NSInteger page = _imageGallery.page;
        PHAsset *asset = _assets[page];
        if (_imageGallery.isPlayingVideo && !asset.rg_isImage && _player.rate > 0) {
            isPlayingVideo = YES;
        }
    }
    
    if (forGallery && !_toolBarItemGallery) {
        _toolBarItemGallery = [self __createToolBarItmes];
    }
    
    if (!forGallery && !_toolBarItem) {
        _toolBarItem = [self __createToolBarItmes];
    }
    
    NSMutableArray <UIBarButtonItem *> *array = forGallery ? _toolBarItemGallery : _toolBarItem;
    
    // 0: countItem
    UIBarButtonItem *countItem = array[0];
    UIButton *label = countItem.customView;
    NSString *text = @(self.cache.pickPhotos.count).stringValue;
    
    if (![text isEqualToString:[label titleForState:UIControlStateNormal]]) {
        [label setTitle:text forState:UIControlStateNormal];
        [label sizeToFit];
        CGFloat width = MAX(label.frame.size.width + 8, 26);
        label.frame = CGRectMake(0, 0, width, 26);
    }
    countItem.customView = label;
    label.hidden = _toolBarModePreview || (isPlayingVideo && self.player.rate > 0);
    
    // 2: center
    UIBarButtonItem *centerItem = array[2];
    if (forGallery) {
        NSInteger page = _imageGallery.page;
        PHAsset *asset = _assets[page];
        
        if (isPlayingVideo && !asset.rg_isImage) {
            if (centerItem.tag != 4) {
                centerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(__pauseCurrentPlayer)];
                centerItem.enabled = YES;
                centerItem.tag = 4;
                [array replaceObjectAtIndex:2 withObject:centerItem];
            }
        } else {
            if (_toolBarModePreview || [self.cache contain:asset]) {
                if (centerItem.tag != 2) {
                    centerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(__selectItemWithCurrentGalleryPage)];
                    centerItem.tag = 2;
                    [array replaceObjectAtIndex:2 withObject:centerItem];
                }
            } else {
                if (!asset.rg_isImage ||
                    [self.cache loadStatusCacheForAsset:asset]) {
                    if (centerItem.tag != 1) {
                        centerItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(__selectItemWithCurrentGalleryPage)];
                        centerItem.enabled = !self.cache.isFull;
                        centerItem.tag = 1;
                        [array replaceObjectAtIndex:2 withObject:centerItem];
                    }
                } else {
                    if (!centerItem.customView) {
                        UIActivityIndicatorView *loading = [UIActivityIndicatorView new];
                        loading.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
                        [loading sizeToFit];
                        [loading startAnimating];
                        centerItem.customView = loading;
                        centerItem.tag = 3;
                    }
                }
            }
        }
    } else {
        centerItem.enabled = NO;
        centerItem.tintColor = [UIColor clearColor];
    }
    
    // downItem
    UIBarButtonItem *downItem = array[4];
    downItem.enabled = self.cache.pickPhotos.count && !isPlayingVideo;
    downItem.tintColor = isPlayingVideo ? UIColor.clearColor : nil;
    return array;
}

#pragma mark - RGImageGalleryAdditionUIConfig

- (BOOL)imageGallery:(RGImageGallery *)imageGallery toolBarItemsShouldDisplayForIndex:(NSInteger)index {
    return YES;
}

- (NSArray<UIBarButtonItem *> *)imageGallery:(RGImageGallery *)imageGallery toolBarItemsForIndex:(NSInteger)index {
    if ([_target respondsToSelector:@selector(customToolBarItemsAtIndex:forImagePickerViewGalleryDelegate:)]) {
        return [_target customToolBarItemsAtIndex:index forImagePickerViewGalleryDelegate:self];
    }
    return [self toolBarItemForGallery:YES];
}

- (BOOL)imageGallery:(RGImageGallery *)imageGallery isVideoAtIndex:(NSInteger)index {
    PHAsset *asset = self.assets[index];
    return asset.rg_isVideo;
}

- (UIImage *)playButtonImageWithImageGallery:(RGImageGallery *)imageGallery atIndex:(NSInteger)index {
    PHAsset *asset = self.assets[index];
    if (asset.rg_isLive) {
        return nil;
    }
    return self.config.playIcon;
}

- (void)imageGallery:(RGImageGallery *)imageGallery configFrontView:(RGImageGalleryView *)frontView atIndex:(NSInteger)index {
    [frontView clearSubviews];
    PHAsset *asset = self.assets[index];
    if (index == imageGallery.page && !asset.rg_isImage && imageGallery.isPlayingVideo) {
        RGAVAssetTracksView *tracks = [RGAVAssetTracksView viewWithAVAsset:[self.player rg_valueforConstKey:"AVAsset"]];
        [tracks addTarget:self action:@selector(__seekCurrentPlayer:) forControlEvents:UIControlEventValueChanged];
        [tracks addTarget:self action:@selector(__seekCurrentPlayerBegin:) forControlEvents:UIControlEventTouchDragEnter];
        [tracks addTarget:self action:@selector(__seekCurrentPlayerEnd:) forControlEvents:UIControlEventTouchDragExit];
        
        _tracks = tracks;
        [frontView addSubview:tracks];
        frontView.tintColor = self.config.tintColor;
        
        __weak typeof(tracks) wTracks = tracks;
        frontView.layout = ^(UIView * _Nonnull wrapper, RGImageGallery * _Nonnull imageGallery) {
            UIToolbar *toolbar = imageGallery.toolbar;
            CGRect frame = toolbar.frame;
            frame.origin = CGPointMake(0, CGRectGetMinY(frame) - frame.size.height);
            wTracks.frame = frame;
        };
    } else if (asset.rg_isLive) {
        if (@available(iOS 9.1, *)) {
            UIImage *image = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            
            [button setImage:image forState:UIControlStateNormal];
            [button setTitle:@"Live  " forState:UIControlStateNormal];
            [button.titleLabel setFont:[UIFont systemFontOfSize:13.f]];
            
            [button sizeToFit];
            button.tintColor = UIColor.darkGrayColor;
            button.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
            button.userInteractionEnabled = NO;
            button.layer.cornerRadius = 4;
            button.layer.masksToBounds = YES;
            
            [frontView addSubview:button];
            
            frontView.layout = ^(UIView * _Nonnull wrapper, RGImageGallery * _Nonnull imageGallery) {
                UIEdgeInsets edge = imageGallery.rg_layoutSafeAreaInsets;
                CGRect frame = button.frame;
                frame.origin = CGPointMake(10, edge.top > 20 ? (edge.top+ 10) : frame.origin.y);
                button.frame = frame;
            };
        }
    }
}

#pragma mark - RGImageGalleryDelegate

- (BOOL)imageGallery:(RGImageGallery *)imageGallery
    playVideoAtIndex:(NSInteger)index
           videoView:(nonnull RGImageGalleryView *)videoView
          completion:(nonnull void (^)(void))completion {
    
    if (self.loadIndex == index && imageGallery.isPlayingVideo) {
        [imageGallery showVideoButton:NO];
        [self __playCurrentPlayer];
        return NO;
    }
    
    PHAsset *asset = self.assets[index];
    self.loadIndex = index;
    
    if (asset.rg_isLive) {
        if (@available(iOS 9.1, *)) {
            self.reqVideoId =
            [RGImagePicker loadLivePhotoFromAsset:asset networkAccessAllowed:YES progressHandler:^(double progress) {
                
            } completion:^(NSDictionary * _Nullable resource, NSError * _Nullable error) {
                if (index != self.loadIndex) {
                    return;
                }
                PHLivePhoto *livePhoto = resource[RGImagePickerResourceLivePhotoInstance];
                if (!livePhoto) {
                    completion();
                    return;
                }
                
                PHLivePhotoView *liveView = [[PHLivePhotoView alloc] init];
                liveView.livePhoto = livePhoto;
                [videoView addSubview:liveView];
                
                videoView.layout = ^(UIView * _Nonnull wrapper, RGImageGallery * _Nonnull imageGallery) {
                    [CATransaction begin];
                    [CATransaction setDisableActions:YES];
                    liveView.frame = wrapper.bounds;
                    [CATransaction commit];
                };
                [imageGallery reloadToolBarItem];
            }];
        }
    } else {
        [imageGallery setLoading:YES];
        self.reqVideoId =
        [RGImagePicker loadVideoFromAsset:asset loadOption:RGImagePickerLoadVideoAutoQuality networkAccessAllowed:YES progressHandler:^(double progress) {
            
        } completion:^(NSDictionary * _Nullable resource, NSError * _Nullable error) {
            if (index != self.loadIndex) {
                return;
            }
            [imageGallery setLoading:NO];
            
            AVAsset *avAsset = resource[RGImagePickerResourceAVAssetInstance];
            if (!avAsset) {
                completion();
                return;
            }
            
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:avAsset];
            AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
            
            AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            playerLayer.frame = videoView.bounds;
            
            [videoView.layer addSublayer:playerLayer];
            videoView.layout = ^(UIView * _Nonnull wrapper, RGImageGallery * _Nonnull imageGallery) {
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                playerLayer.frame = wrapper.bounds;
                [CATransaction commit];
            };
            
            [player play];
            self.player = player;
            self.playerLayer = playerLayer;
            __weak typeof(self) wSelf = self;
            __block id token = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:playerItem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                if (note.object == wSelf.player.currentItem) {
                    [[NSNotificationCenter defaultCenter] removeObserver:token];
                    completion();
                }
            }];
            
            CGFloat duration = CMTimeGetSeconds(avAsset.duration);
            CGFloat fps = [[[avAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] nominalFrameRate];
            CMTime interval = CMTimeMake(1, fps);
            id timeToken = [player addPeriodicTimeObserverForInterval:interval queue:nil usingBlock:^(CMTime time) {
                CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;
                [wSelf __updateVideoSliderWithSumDuration:duration currentDuration:currentSecond];
            }];
            
            [self.player rg_setValue:token forConstKey:"AVPlayerNotiToken" retain:YES];
            [self.player rg_setValue:timeToken forConstKey:"AVPlayerTimeToken" retain:YES];
            [self.player rg_setValue:avAsset forConstKey:"AVAsset" retain:YES];
            
            [imageGallery reloadToolBarItem];
            [imageGallery reloadFrontView];
        }];
    }
    return YES;
}

- (void)imageGallery:(RGImageGallery *)imageGallery pauseVideoAtIndex:(NSInteger)index videoView:(nonnull RGImageGalleryView *)videoView {
    [self __pauseCurrentPlayer];
}

- (void)imageGallery:(RGImageGallery *)imageGallery stopVideoAtIndex:(NSInteger)index videoView:(nonnull RGImageGalleryView *)videoView {
    if (self.loadIndex == index) {
        [RGImagePicker cancelLoadResourceWithRequestId:self.reqVideoId];
        self.loadIndex = -1;
        self.reqVideoId = -1;
        [imageGallery setLoading:NO];
    }
    [self __clearCurrentPlayer];
    [imageGallery reloadToolBarItem];
    [imageGallery reloadFrontView];
}

#pragma mark - Play Control

- (void)__pauseCurrentPlayer {
    [self.player pause];
    [self.imageGallery showVideoButton:YES];
    [self.imageGallery reloadToolBarItem];
}

- (void)__stopCurrentPlayer {
    [self.imageGallery stopCurrentVideo];
    [self.imageGallery reloadToolBarItem];
}

- (void)__playCurrentPlayer {
    if (_tracks.isTracking) {
        return;
    }
    [self.player play];
    [self.imageGallery reloadToolBarItem];
}

- (void)__updateVideoSliderWithSumDuration:(CGFloat)sDuration currentDuration:(CGFloat)cDuration {
    if (_tracks.isTracking) {
        return;
    }
    _tracks.time = self.player.currentItem.currentTime;
}

- (void)__seekCurrentPlayer:(RGAVAssetTracksView *)slider {
    if (!_player) {
        return;
    }
    [_player rg_seekToTime:slider.time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
}

- (void)__seekCurrentPlayerBegin:(RGAVAssetTracksView *)slider {
    [_player pause];
    [self.imageGallery showVideoButton:NO];
    [self.imageGallery reloadToolBarItem];
}

- (void)__seekCurrentPlayerEnd:(RGAVAssetTracksView *)slider {
    [self.imageGallery showVideoButton:YES];
}

- (void)__clearCurrentPlayer {
    if (!self.player) {
        return;
    }
    
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];
    
    AVPlayerItem *item = self.player.currentItem;
    [item cancelPendingSeeks];
    [item.asset cancelLoading];
    
    id token = [self.player rg_valueforConstKey:"AVPlayerNotiToken"];
    if (token) {
        [self.player rg_setValue:nil forConstKey:"AVPlayerNotiToken" retain:NO];
        [[NSNotificationCenter defaultCenter] removeObserver:token];
    }
    token = [self.player rg_valueforConstKey:"AVPlayerTimeToken"];
    if (token) {
        [self.player removeTimeObserver:token];
    }
    
    self.player = nil;
    self.playerLayer = nil;
}

#pragma mark - Private

- (NSMutableArray <UIBarButtonItem *> *)__createToolBarItmes {
    
    NSMutableArray *array = [NSMutableArray array];
    
    UIBarButtonItem *countItem = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:nil action:nil];
    
    UIButton *button = [[UIButton alloc] init];
    [button setBackgroundImage:[UIImage rg_templateImageWithSize:CGSizeMake(1, 1)] forState:UIControlStateNormal];
    button.layer.cornerRadius = 10;
    button.titleLabel.font = [UIFont systemFontOfSize:16];
    button.clipsToBounds = YES;
    countItem.customView = button;
    [button addTarget:self action:@selector(__showPickerPhotos:) forControlEvents:UIControlEventTouchUpInside];
    [array addObject:countItem];
    
    [array addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(__selectItemWithCurrentGalleryPage)];
    addItem.tag = 1;
    [array addObject:addItem];
    
    [array addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    
    UIBarButtonItem *down = [[UIBarButtonItem alloc] initWithImage:self.config.sendIcon style:UIBarButtonItemStyleDone target:self action:@selector(__down)];
    [array addObject:down];
    
    return array;
}

- (void)__selectItemWithCurrentGalleryPage {
    if ([_target respondsToSelector:@selector(imagePickerViewGalleryDelegate:selectAssetAtIndex:)]) {
        [_target imagePickerViewGalleryDelegate:self selectAssetAtIndex:_imageGallery.page];
    }
}

- (void)__showPickerPhotos:(UIButton *)sender {
    [self.cache showPickerPhotosWithParentViewController:self.viewController];
}

- (void)__down {
    [self.cache callBack:self.viewController];
}

- (void)dealloc {
    [_imageGallery stopCurrentVideo];
    [self __clearCurrentPlayer];
}

@end
