//
//  RGAVPlayerItemTracks.m
//  CampTalk
//
//  Created by renge on 2019/9/4.
//  Copyright © 2019 yuru. All rights reserved.
//

#import "RGAVAssetTracksView.h"
#import <RGUIKit/RGUIKit.h>

@interface RGAVAssetTrackCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation RGAVAssetTrackCell

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

@end

@interface RGAVAssetTracksView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate> {
    CGFloat _fps;
    BOOL _isDrag;
}

@property (nonatomic, strong) UIVisualEffectView *backgroundView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *cursor;
@property (nonatomic, strong) UILabel *leftTimeLabel;

@property (nonatomic, strong) AVAssetImageGenerator *generator;
@property (nonatomic, strong) NSArray <UIImage *> *tracks;

@end

@implementation RGAVAssetTracksView

+ (RGAVAssetTracksView *)viewWithAVAsset:(AVAsset *)asset {
    RGAVAssetTracksView *view = [[RGAVAssetTracksView alloc] init];
    view.asset = asset;
    return view;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _backgroundView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
        _backgroundView.frame = self.bounds;
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self addSubview:_backgroundView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = _collectionView.frame.size.width/2;
    _collectionView.contentInset = UIEdgeInsetsMake(0, width, 0, width);
    _cursor.frame = CGRectMake(width - 10, 0, 20, self.bounds.size.height);
    _leftTimeLabel.center = CGPointMake(10, -_leftTimeLabel.frame.size.height/2 - 5);
    if (_tracks.count) {
        self.time = self.time;
    }
}

- (void)setAsset:(AVAsset *)asset {
    _asset = asset;
    _generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    _generator.appliesPreferredTrackTransform = YES;
    _fps = [[[_asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] nominalFrameRate];
    [self loadImages];
}

- (void)setTime:(CMTime)time {
    _time = time;
    CGFloat sum = CMTimeGetSeconds(_asset.duration);
    CGFloat now = CMTimeGetSeconds(time);
    
    [self __configTimeLabelWithLeftSecond:sum - now];
    
    CGFloat progress = now / sum;
    if (!_collectionView.contentSize.width) {
        [_collectionView layoutIfNeeded];
    }
    CGFloat offSetX = -_collectionView.contentInset.left;
    if (_collectionView.contentSize.width) {
        offSetX += progress*_collectionView.contentSize.width;
    }
    if (!isnan(offSetX)) {
        [_collectionView setContentOffset:CGPointMake(offSetX, 0) animated:NO];
    }
}

- (void)__configTimeLabelWithLeftSecond:(NSInteger)left {
    left = MAX(left, 0);
    NSString *leftString = [NSString stringWithFormat:@"-%02d:%02d", (int)left/60, (int)left%60];
    _leftTimeLabel.text = leftString;
}

- (void)loadImages {
    // Generate the @2x equivalent
    _generator.maximumSize = CGSizeMake(200.0f, 0.0f);             // 2
    
    CMTime duration = _asset.duration;
    
    NSMutableArray *times = [NSMutableArray array];                         // 3
    CMTimeValue increment = duration.value / 20;
    CMTimeValue currentValue = 2.0 * duration.timescale;
    while (currentValue <= duration.value) {
        CMTime time = CMTimeMake(currentValue, duration.timescale);
        [times addObject:[NSValue valueWithCMTime:time]];
        currentValue += increment;
    }
    
    __block NSUInteger imageCount = times.count;                            // 4
    __block NSMutableArray *images = [NSMutableArray array];
    
    AVAssetImageGeneratorCompletionHandler handler;                         // 5
    
    handler = ^(CMTime requestedTime,
                CGImageRef imageRef,
                CMTime actualTime,
                AVAssetImageGeneratorResult result,
                NSError *error) {
        
        if (result == AVAssetImageGeneratorSucceeded) {                     // 6
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            [images addObject:image];
        } else {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
        
        // If the decremented image count is at 0, we're all done.
        if (--imageCount == 0) {                                            // 7
            dispatch_async(dispatch_get_main_queue(), ^{
                //获取完毕， 作出相应的操作
                self.tracks = images;
                [self.collectionView reloadData];
            });
        }
    };
    
    [self.generator generateCGImagesAsynchronouslyForTimes:times       // 8
                                         completionHandler:handler];
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0.f;
        layout.minimumLineSpacing = 0.f;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = UIColor.clearColor;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:RGAVAssetTrackCell.class forCellWithReuseIdentifier:NSStringFromClass(RGAVAssetTrackCell.class)];
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [self addSubview:_collectionView];
        
        _cursor = [UIView new];
        _cursor.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        _cursor.frame = CGRectMake(0, 0, 20, 20);
        
        UIButton *line = [UIButton buttonWithType:UIButtonTypeSystem];
        [line setBackgroundImage:[UIImage rg_templateImageWithSize:CGSizeMake(1, 1)] forState:UIControlStateNormal];
        line.frame = CGRectMake(10, 0, 1, 20);
        line.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        line.userInteractionEnabled = NO;
        _cursor.userInteractionEnabled = NO;
        [_cursor addSubview:line];
        [_cursor addSubview:self.leftTimeLabel];
        [self addSubview:_cursor];
    }
    return _collectionView;
}

- (UILabel *)leftTimeLabel {
    if (!_leftTimeLabel) {
        _leftTimeLabel = [UILabel new];
        _leftTimeLabel.text = @" 00:00 ";
        _leftTimeLabel.textColor = self.tintColor;
        _leftTimeLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        _leftTimeLabel.textAlignment = NSTextAlignmentCenter;
        
        _leftTimeLabel.layer.cornerRadius = 3.f;
        _leftTimeLabel.layer.masksToBounds = YES;
        
        [_leftTimeLabel setFont:[UIFont systemFontOfSize:12]];
        [_leftTimeLabel sizeToFit];
        _leftTimeLabel.frame = UIEdgeInsetsInsetRect(_leftTimeLabel.frame, UIEdgeInsetsMake(-5, -5, -5, -5));
        _leftTimeLabel.userInteractionEnabled = NO;
    }
    return _leftTimeLabel;
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    _leftTimeLabel.textColor = self.tintColor;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.tracks.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RGAVAssetTrackCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(RGAVAssetTrackCell.class) forIndexPath:indexPath];
    cell.imageView.image = self.tracks[indexPath.row];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_isDrag) {
        return;
    }
    if (!_collectionView.contentSize.width) {
        return;
    }
    CGFloat progress = (_collectionView.contentOffset.x + _collectionView.contentInset.left)/_collectionView.contentSize.width;
    progress = MAX(0 ,MIN(1, progress));
    
    CGFloat sum = CMTimeGetSeconds(_asset.duration);
    CGFloat seconds = progress * sum;
    _time = CMTimeMakeWithSeconds(seconds, _fps);
    
    CGFloat now = CMTimeGetSeconds(_time);
    [self __configTimeLabelWithLeftSecond:sum - now];
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _isDrag = YES;
    [self sendActionsForControlEvents:UIControlEventTouchDragEnter];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        [self scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _isDrag = NO;
    [self sendActionsForControlEvents:UIControlEventTouchDragExit];
}

- (BOOL)isTracking {
    return _isDrag;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger count = MIN(self.tracks.count, 4);
    return CGSizeMake(collectionView.frame.size.width / count, collectionView.frame.size.height);
}

#pragma mark - UIControl

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    [super addTarget:target action:action forControlEvents:controlEvents];
}

@end
