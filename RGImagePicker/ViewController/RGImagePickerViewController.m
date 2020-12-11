//
//  CTImagePickerViewController.m
//  CampTalk
//
//  Created by renge on 2018/5/7.
//  Copyright © 2018年 yuru. All rights reserved.
//

#import "RGImagePickerViewController.h"
#import "RGImageAlbumListViewController.h"

#import <RGUIKit/RGUIKit.h>
#import <FLAnimatedImageView_RGWrapper/FLAnimatedImageView+RGWrapper.h>
#import <Photos/Photos.h>
#import <PhotosUI/PHLivePhotoView.h>
#import "RGAVAssetTracksView.h"
#import <AVFoundation/AVFoundation.h>

#import "RGImageGallery.h"
#import "RGImagePickerConst.h"
#import "RGImagePicker.h"
#import "RGImagePickerCache.h"

#import "RGImagePickerCell.h"
#import "UIImage+RGPickerIcon.h"
#import "AVPlayer+RGSeekSmoothly.h"
#import "RGImagePickerViewGalleryDelegate.h"

static PHImageRequestOptions *requestOptions = nil;
static NSString *_RGImagePickerCellId = @"RGImagePickerCell";

@interface RGImagePickerViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver, RGImagePickerCellDelegate, RGImageGalleryDataSource, RGImageGalleryPushTransitionDelegate, RGImagePickerViewGalleryDelegateTarget>

@property (nonatomic, assign) BOOL needScrollToBottom;
@property (nonatomic, assign) BOOL needRequestLoadStatus;
@property (nonatomic, assign) BOOL needResetView;
@property (nonatomic, assign) BOOL needSyncLoad;
@property (nonatomic, strong) PHFetchResult<PHAsset *> *assets;

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, assign) CGRect previousPreheatRect;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UILabel *privacyLabel;

@property (nonatomic, assign) CGSize thumbSize;
@property (nonatomic, assign) CGSize lowThumbSize;

@property (nonatomic, strong) NSIndexPath *recordMaxIndexPath;

@property (nonatomic, weak) RGImageGallery *imageGallery;
@property (nonatomic, assign) BOOL interactionAnimate;

@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) RGAVAssetTracksView *tracks;

@property (nonatomic, strong) UIButton *toolBarLabel;
@property (nonatomic, strong) UIButton *toolBarLabelGallery;

@property (nonatomic, strong) NSMutableArray <UIBarButtonItem *> *toolBarItem;
@property (nonatomic, strong) NSMutableArray <UIBarButtonItem *> *toolBarItemGallery;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) NSInteger loadIndex;
@property (nonatomic, assign) NSInteger reqVideoId;

@property (nonatomic, strong) RGImagePickerViewGalleryDelegate *galleryDelegate;
@end

@implementation RGImagePickerViewController

#pragma mark - Life Cycle

- (instancetype)init {
    if (self = [super init]) {
        self.galleryDelegate = [RGImagePickerViewGalleryDelegate new];
        self.galleryDelegate.viewController = self;
        self.galleryDelegate.target = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.needRequestLoadStatus = YES;
    self.view.tintColor = self.config.tintColor;
    self.view.backgroundColor = self.config.backgroundColor;
    
    UILabel *label = nil;
    if (PHPhotoLibrary.authorizationStatus != PHAuthorizationStatusAuthorized) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.numberOfLines = 0;
        if ([self.config.privacyDescriptionString isKindOfClass:NSString.class]) {
            label.text = self.config.privacyDescriptionString;
        } else {
            label.attributedText = self.config.privacyDescriptionString;
        }
        label.textAlignment = NSTextAlignmentCenter;
    }
    
    UIImage *image = self.config.backgroundImage;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    
    if (self.config.backgroundBlurRadius || label) {
        RGBluuurView *bluuurView = [[RGBluuurView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        bluuurView.blurRadius = self.config.backgroundBlurRadius;
        bluuurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        bluuurView.frame = imageView.bounds;
        [imageView addSubview:bluuurView];
        
        if (label) {
            label.frame = imageView.bounds;
            if (image) {
                UIVisualEffectView *subEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIVibrancyEffect effectForBlurEffect:(UIBlurEffect *)bluuurView.effect]];
                subEffectView.frame = bluuurView.bounds;
                subEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [bluuurView.contentView addSubview:subEffectView];
                [subEffectView.contentView addSubview:label];
            } else {
                [imageView addSubview:label];
            }
        }
    }
    _privacyLabel = label;
    _backgroundView = imageView;
    
    [self.view addSubview:_backgroundView];

    [self.view addSubview:self.collectionView];
    
    [self.collectionView registerClass:[RGImagePickerCell class] forCellWithReuseIdentifier:@"RGImagePickerCell"];
    self.collectionView.allowsMultipleSelection = self.cache.maxCount > 1;
    
    UIBarButtonItem *down = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(rg_dismiss)];
    self.navigationItem.rightBarButtonItem = down;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.toolBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.toolBar.items = [self.galleryDelegate toolBarItemForGallery:NO];
    [self.view addSubview:self.toolBar];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeLeading
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.toolBar
                                                          attribute:NSLayoutAttributeLeading
                                                         multiplier:1
                                                           constant:0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeTrailing
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.toolBar
                                                          attribute:NSLayoutAttributeTrailing
                                                         multiplier:1
                                                           constant:0]];
    
    [self.toolBar updateConstraints];
    if (@available(iOS 11.0, *)) {;
        [self.toolBar.lastBaselineAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    } else {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.toolBar
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:0]];
    }
    [self __configViewWithCurrentCollection:NO];
    [self setNeedScrollToBottom:YES];
    
    UIPinchGestureRecognizer *pin = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pin:)];
    [self.collectionView addGestureRecognizer:pin];
    
//    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
//    [self.collectionView addGestureRecognizer:pan];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self __doLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self __doLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    [self __scrollToBottomIfNeed];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.presentingViewController setNeedsStatusBarAppearanceUpdate];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self __configItemSize];
    [self __doReloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
        return;
    }
    [RGImagePicker cancelLoadResourceWithRequestId:self.reqVideoId];
    [self resetCachedAssets];
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark - Getter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0.f;
        layout.minimumLineSpacing = 2.f;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        [self __configItemSize];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}

- (UIToolbar *)toolBar {
    if (!_toolBar) {
        _toolBar = [[UIToolbar alloc] init];
    }
    return _toolBar;
}

- (void)setCollection:(PHAssetCollection *)collection {
    _collection = collection;
    PHFetchOptions *op = self.config.option;
    _assets = [PHAsset fetchAssetsInAssetCollection:_collection options:op];
    self.galleryDelegate.assets = _assets;
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    [self __configViewWithCurrentCollection:YES];
}

- (void)setCache:(RGImagePickerCache *)cache {
    _cache = cache;
    self.galleryDelegate.cache = cache;
}

- (RGImagePickerConfig *)config {
    return self.cache.config;
}

#pragma mark - Config

- (void)__doLayout {
    CGFloat recordHeight = self.collectionView.frame.size.height;
    [_collectionView rg_setAdditionalContentInset:UIEdgeInsetsMake(0, 0, self.toolBar.frame.size.height, 0) safeArea:self.rg_layoutSafeAreaInsets];
    _collectionView.scrollIndicatorInsets = _collectionView.contentInset;
    _collectionView.frame = self.view.bounds;
    _backgroundView.frame = self.view.bounds;
    
    if (_privacyLabel) {
        _privacyLabel.frame = UIEdgeInsetsInsetRect(self.view.bounds, UIEdgeInsetsMake(0, 40, 0, 40));
    }
    
    [_collectionView rg_setAdditionalContentInset:UIEdgeInsetsMake(0, 0, self.toolBar.frame.size.height, 0) safeArea:self.rg_layoutSafeAreaInsets];
    _collectionView.scrollIndicatorInsets = _collectionView.contentInset;
    
    if (recordHeight != self.view.bounds.size.height) {
        [self __configItemSize];
        [self __doReloadData];
    }
    if (_needScrollToBottom) {
        [self __scrollViewToBottom];
    } else {
        if (recordHeight != self.collectionView.frame.size.height) {
            
            if (!_recordMaxIndexPath) {
                return;
            }
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__recordMaxIndexPathIfNeed) object:nil];
            
            [self.collectionView scrollToItemAtIndexPath:self.recordMaxIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__recordMaxIndexPathIfNeed) object:nil];
                
                [UIView performWithoutAnimation:^{
                    [self.collectionView scrollToItemAtIndexPath:self.recordMaxIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
                }];
            });
        }
    }
}

- (void)__configViewWithCurrentCollection:(BOOL)scrollToBottom {
    if (!self.isViewLoaded) {
        return;
    }
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
        return;
    }
    if (_privacyLabel) {
        [_privacyLabel removeFromSuperview];
        _privacyLabel = nil;
    }
    if (!_imageManager) {
        _imageManager = (PHCachingImageManager *)[PHCachingImageManager new];
        _imageManager.allowsCachingHighQualityImages = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(__imagePickerCachePickPhotosHasChanged:) name:RGImagePickerCachePickPhotosHasChanged object:nil];
    }
    [self resetCachedAssets];
    [self __configTitle];
    if (scrollToBottom) {
        [self setNeedScrollToBottom:YES];
        [self __doReloadData];
        [self __scrollToBottomIfNeed];
    }
}

- (void)__configTitle {
    if (_collection) {
        NSString *title = [NSString stringWithFormat:@"%@ (%lu/%lu)", _collection.localizedTitle, (unsigned long)self.cache.pickPhotos.count, (unsigned long)self.cache.maxCount];
        self.navigationItem.title = title;
    }
}

- (void)__scrollToBottomIfNeed {
    if (_needScrollToBottom && _assets) {
        if (_assets.count <= 0) {
            _needScrollToBottom = NO;
            return;
        }
        
        self.collectionView.alpha = 0;
        [self.collectionView setNeedsLayout];
        [self.collectionView layoutIfNeeded];
        [self __scrollViewToBottom];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_needScrollToBottom = NO;
            
            [UIView animateWithDuration:0.5 animations:^{
                self.collectionView.alpha = 1;
                self.needResetView = NO;
                self.needSyncLoad = YES;
                self.needRequestLoadStatus = YES;
                [self __doReloadData];
            } completion:^(BOOL finished) {
                self.needResetView = YES;
                self.needSyncLoad = NO;
            }];
        });
    }
}

- (void)__scrollViewToBottom {
//    BOOL record = self.needRequestLoadStatus;
    [self.collectionView rg_scrollViewToBottom:NO];
//    self.needRequestLoadStatus = record;
}

- (void)__configItemSize {    
    CGFloat space = 2.f;
    CGRect bounds = self.rg_safeAreaBounds;
    CGFloat contaiWidth = MIN(bounds.size.width, bounds.size.height);
    NSInteger count = 4 ;
    CGFloat width = contaiWidth - (count > 0 ? (count - 1) * space : 0);
    width = 1.f * width / count;
    
//    if (width < 80) {
//        contaiWidth = _collectionView.bounds.size.width;
//        count = contaiWidth / (80 + space);
//        width = contaiWidth - (count > 0 ? (count - 1) * space : 0);
//        width = 1.f * width / count;
//    }
    _itemSize = CGSizeMake(width, width);
    _lowThumbSize = CGSizeMake(width, width);
    width = floor(width * [UIScreen mainScreen].scale);
    _thumbSize = CGSizeMake(width, width);
}

- (void)__down {
    [self.cache callBack:self];
}

- (void)__doReloadData {
//    [CATransaction begin];
//    [CATransaction setDisableActions:YES];
    [self.collectionView reloadData];
//    [CATransaction commit];
}

- (void)__showPickerPhotos:(UIButton *)sender {
    [self.cache showPickerPhotosWithParentViewController:self];
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _assets.count;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.needRequestLoadStatus = NO;
    [self updateCachedAssets];
//    CGFloat speed = fabs(self.lastOffset.y - scrollView.contentOffset.y);
//    if (speed < 10) {
//        self.needRequestLoadStatus = YES;
//        NSLog(@"load! %f", speed);
//    } else {
//        self.needRequestLoadStatus = NO;
//    }
//    self.lastOffset = scrollView.contentOffset;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self __loadStatusWtihResetView:NO];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self __loadStatusWtihResetView:NO];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.needRequestLoadStatus = NO;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__loadStatusWtihResetView:) object:@(NO)];
        [self performSelector:@selector(__loadStatusWtihResetView:) withObject:@(NO) afterDelay:0.3];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self __loadStatusWtihResetView:NO];
}

- (void)__loadStatusWtihResetView:(BOOL)resetView {
    self.needRequestLoadStatus = YES;
    self.needResetView = resetView;
    NSArray<__kindof UICollectionViewCell *> *visibleCells = self.collectionView.visibleCells;
    NSArray<NSIndexPath *> *indexPathsForVisibleRows = self.collectionView.indexPathsForVisibleItems;
    [visibleCells enumerateObjectsUsingBlock:^(RGImagePickerCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.asset = nil;
        [self __configCell:obj withIndexPath:indexPathsForVisibleRows[idx]];
    }];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    RGImagePickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:_RGImagePickerCellId forIndexPath:indexPath];
    cell.delegate = self;
    if (indexPath.row >= _assets.count) {
        return cell;
    }
    if (!_needScrollToBottom) {
        [self __configCell:cell withIndexPath:indexPath];
    }
    return cell;
}

- (void)__configCell:(RGImagePickerCell *)cell withIndexPath:(NSIndexPath *)indexPath {
    
    PHAsset *asset = _assets[indexPath.row];
    CGSize targetSize = _needRequestLoadStatus ? _thumbSize : _lowThumbSize;
    [cell setAsset:asset photoManager:_imageManager options:requestOptions targetSize:targetSize cache:_cache sync:!_needRequestLoadStatus loadStatus:_needRequestLoadStatus resetView:_needResetView];
    if ([self.cache contain:asset]) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [cell setSelected:YES];
    } else {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        [cell setSelected:NO];
    }
    
    if (_imageGallery.page == indexPath.row) {
        if (_imageGallery.pushState > RGImageGalleryPushStateNoPush) {
            cell.contentView.alpha = 0;
        } else {
            cell.contentView.alpha = 1;
        }
    } else {
        cell.contentView.alpha = 1;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return _itemSize;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!_recordMaxIndexPath) {
        [self __recordMaxIndexPathIfNeed];
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__recordMaxIndexPathIfNeed) object:nil];
        [self performSelector:@selector(__recordMaxIndexPathIfNeed) withObject:nil afterDelay:0.3f inModes:@[NSRunLoopCommonModes]];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    RGImagePickerCell *cell = (RGImagePickerCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell.lastTouchForce == 0) {
        PHAsset *photo = _assets[indexPath.row];
        if (![self.cache loadStatusCacheForAsset:photo]) {
            [RGImagePickerCell loadOriginalWithAsset:photo cache:self.cache updateCell:cell collectionView:collectionView progressHandler:nil completion:nil];
            return NO;
        }
        RGImageGallery *imageGallery = [[RGImageGallery alloc] initWithPlaceHolder:self.config.loadFailedImage andDataSource:self];
        imageGallery.pushTransitionDelegate = self;
        
        self.galleryDelegate.imageGallery = imageGallery;
        
        imageGallery.delegate = self.galleryDelegate;
        imageGallery.additionUIConfig = self.galleryDelegate;
        
        imageGallery.pushFromView = YES;
        [imageGallery showImageGalleryAtIndex:indexPath.row fatherViewController:self];
        self.imageGallery = imageGallery;
        return NO;
    }
    return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self collectionView:collectionView shouldSelectItemAtIndexPath:indexPath];
}

#pragma mark - Private Method

- (void)__recordMaxIndexPathIfNeed {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__recordMaxIndexPathIfNeed) object:nil];
    
    [self.collectionView.indexPathsForVisibleItems enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            self.recordMaxIndexPath = obj;
        } else {
            if (self.recordMaxIndexPath.row < obj.row) {
                self.recordMaxIndexPath = obj;
            }
        }
    }];
    _recordMaxIndexPath = _recordMaxIndexPath.copy;
}

- (void)__selectItemWithCurrentGalleryPage {
    [self __selectItemAtIndex:_imageGallery.page orCell:nil];
}

- (void)__selectItemAtIndex:(NSInteger)index orCell:(RGImagePickerCell *_Nullable)cell {
    PHAsset *asset = self->_assets[index];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    if (!cell) {
        cell = (RGImagePickerCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    }
    
    BOOL isFull = self.cache.isFull;
    void(^updateCollectionViewIfNeed)(void) = ^{
        if (self.cache.isFull != isFull) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            NSMutableArray *visiable = [NSMutableArray arrayWithArray:self.collectionView.indexPathsForVisibleItems];
            [visiable removeObject:indexPath];
            [self.collectionView reloadItemsAtIndexPaths:visiable];
            [CATransaction commit];
        }
    };
    
    if (indexPath) {
        if ([self.cache contain:asset]) {
            [self.cache removePhotos:@[asset]];
            [cell setSelected:NO animated:YES];
            [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        } else {
            [self.cache requestLoadStatusWithAsset:asset onlyCache:NO cacheSync:NO result:^(BOOL needLoad) {
                if (needLoad) {
                    [RGImagePickerCell loadOriginalWithAsset:asset cache:self.cache updateCell:cell collectionView:self.collectionView progressHandler:nil completion:nil];
                } else {
                    if (self.cache.maxCount <= 1) {
                        [self.cache setPhotos:@[asset]];
                        [cell setSelected:YES animated:YES];
                        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                    } else {
                        if (self.cache.pickPhotos.count < self.cache.maxCount) {
                            [self.cache addPhotos:@[asset]];
                            [cell setSelected:YES animated:YES];
                            [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
                        }
                        updateCollectionViewIfNeed();
                    }
                    [self __configViewWhenCacheChanged];
                }
            }];
        }
    }
    updateCollectionViewIfNeed();
    [self __configViewWhenCacheChanged];
}

- (void)__configViewWhenCacheChanged {
    self.toolBar.items = [self.galleryDelegate toolBarItemForGallery:NO];
    [_imageGallery reloadToolBarItem];
    [self __configTitle];
}

- (void)__scrollToIndex:(NSUInteger)index {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    NSIndexPath *needShowIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
    if (![self.collectionView.indexPathsForVisibleItems containsObject:needShowIndexPath]) {
        [self.collectionView scrollToItemAtIndexPath:needShowIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
    [self.collectionView setNeedsLayout];
    [self.collectionView layoutIfNeeded];
    [CATransaction commit];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    // https://developer.apple.com/documentation/photokit/phphotolibrarychangeobserver?language=objc
    // Photos may call this method on a background queue;
    // switch to the main queue to update the UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        // Check for changes to the displayed album itself
        // (its existence and metadata, not its member assets).
        
        PHObjectChangeDetails *albumChanges = [changeInstance changeDetailsForObject:self.collection];
        if (albumChanges) {
            // Fetch the new album and update the UI accordingly.
            self->_collection = [albumChanges objectAfterChanges];
            [self __configTitle];
        }
        
        BOOL isFull = self.cache.isFull;
        
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assets];
        if (collectionChanges) {
            
            PHFetchResult <PHAsset *> *newAssets = collectionChanges.fetchResultAfterChanges;
            
            if (collectionChanges.hasIncrementalChanges)  {
                
                UICollectionView *collectionView = self.collectionView;
                NSArray *removedPaths;
                NSArray *insertedPaths;
                NSArray *changedPaths;
                
                NSIndexSet *removed = [collectionChanges removedIndexes];
                removedPaths = [self __indexPathsFromIndexSet:removed];
                
                NSIndexSet *inserted = [collectionChanges insertedIndexes];
                insertedPaths = [self __indexPathsFromIndexSet:inserted];
                
                NSIndexSet *changed = [collectionChanges changedIndexes];
                changedPaths = [self __indexPathsFromIndexSet:changed];
                
                BOOL shouldReload = NO;
                
                if (changedPaths != nil && removedPaths != nil) {
                    for (NSIndexPath *changedPath in changedPaths) {
                        if ([removedPaths containsObject:changedPath]) {
                            shouldReload = YES;
                            break;
                        }
                    }
                }
                
                if (removedPaths.lastObject && ((NSIndexPath *)removedPaths.lastObject).item >= newAssets.count) {
                    shouldReload = YES;
                }
                
                [collectionView performBatchUpdates:^{
                    self.assets = newAssets;
                    self.galleryDelegate.assets = self.assets;
                    if (removed.count) {
                        [collectionView deleteItemsAtIndexPaths:removedPaths];
                        [self.imageGallery deletePages:removed];
                    }
                    
                    if (inserted.count) {
                        [collectionView insertItemsAtIndexPaths:insertedPaths];
                        [self.imageGallery insertPages:inserted];
                    }
                    
                    if (changed.count) {
                        if (!shouldReload) {
                            [collectionView reloadItemsAtIndexPaths:changedPaths];
                        }
                        [self.imageGallery updatePages:changed];
                    }
                    
                    if ([collectionChanges hasMoves]) {
                        [collectionChanges enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                            NSIndexPath *fromIndexPath = [NSIndexPath indexPathForItem:fromIndex inSection:0];
                            NSIndexPath *toIndexPath = [NSIndexPath indexPathForItem:toIndex inSection:0];
                            [collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                        }];
                    }
                    
                } completion:^(BOOL finished) {
                    if (shouldReload || self.cache.isFull != isFull) {
                        [self __doReloadData];
                    }
                }];
            } else {
                self.assets = newAssets;
                self.galleryDelegate.assets = self.assets;
                [self __doReloadData];
            }
        }
    });
}

- (NSArray<NSIndexPath *> *)__indexPathsFromIndexSet:(NSIndexSet *)indexSet {
    if (!indexSet) {
        return nil;
    }
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:indexSet.count];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
    }];
    return array;
}

#pragma mark - RGImagePickerCellDelegate

- (void)imagePickerCell:(RGImagePickerCell *)cell touchForce:(CGFloat)force maximumPossibleForce:(CGFloat)maximumPossibleForce {
    if (maximumPossibleForce) {
        maximumPossibleForce /= 2.5f;
        CGFloat next = MAX(0, (maximumPossibleForce - force) / maximumPossibleForce);
        if (self.view.alpha == 1.0f && next != self.view.alpha) {
            [self feedback];
        }
        self.view.alpha = next;
    }
}

- (void)didCheckForImagePickerCell:(RGImagePickerCell *)cell {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [self __selectItemAtIndex:indexPath.row orCell:cell];
    [self feedback];
}

- (void)feedback {
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
}

#pragma mark - RGImageGalleryDataSource

- (NSInteger)numOfImagesForImageGallery:(RGImageGallery *)imageGallery {
    return _assets.count;
}

- (UIColor *)titleColorForImageGallery:(RGImageGallery *)imageGallery {
    return [UIColor rg_labelColor];
}

- (UIColor *)tintColorForImageGallery:(RGImageGallery *)imageGallery {
    return self.config.tintColor;
}

- (NSString *)titleForImageGallery:(RGImageGallery *)imageGallery atIndex:(NSInteger)index {
    if (index >= 0) {
        BOOL landscape = UIInterfaceOrientationIsLandscape(self.preferredInterfaceOrientationForPresentation);
        PHAsset *assert = _assets[index];
        NSString *title = [[assert creationDate] rg_stringWithDateFormat:@"yyyy-MM-dd HH:mm"];
        if (landscape) {
            return title;
        }
        return [title stringByAppendingFormat:@"\n%ld", (long)index+1];
    } else {
        return @"";
    }
}

- (UIImage *)imageGallery:(RGImageGallery *)imageGallery thumbnailAtIndex:(NSInteger)index targetSize:(CGSize)targetSize {
    PHAsset *asset = _assets[index];
    return [self.cache imageForAsset:asset onlyCache:NO syncLoad:YES allowNet:NO targetSize:self.thumbSize completion:nil];
}

- (UIImage *)imageGallery:(RGImageGallery *)imageGallery
             imageAtIndex:(NSInteger)index
               targetSize:(CGSize)targetSize
              updateImage:(void (^ _Nullable)(UIImage * _Nonnull))updateImage {
    PHAsset *asset = _assets[index];
    if (updateImage) {
        [RGImagePickerCell loadOriginalWithAsset:asset cache:self.cache updateCell:nil collectionView:self.collectionView progressHandler:^(double progress) {
            
        } completion:^(NSData * _Nullable imageData, NSError * _Nullable error) {
            UIImage *image = [UIImage rg_imageOrGifWithData:imageData];
            if (image) {
                updateImage(image);
            }
            if ([self->_assets[imageGallery.page].localIdentifier isEqualToString:asset.localIdentifier]) {
                if (asset.rg_isLive) {
                    [imageGallery startCurrentPageVideo];
                }
                [imageGallery reloadToolBarItem];
            }
        }];
    }
    return nil;
}

- (UIView *)imageGallery:(RGImageGallery *)imageGallery thumbViewForTransitionAtIndex:(NSInteger)index {
    if (index >= 0) {
        if (imageGallery.pushState == RGImageGalleryPushStatePushed) {
            [self __scrollToIndex:index];
        }
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        return cell;
    } else  {
        return nil;
    }
}

#pragma mark - RGImageGalleryPushTransitionDelegate

- (RGIMGalleryTransitionCompletion)imageGallery:(RGImageGallery *)imageGallery willPopToParentViewController:(UIViewController *)viewController {
    
    NSUInteger page = imageGallery.page;
    [self __scrollToIndex:page];
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:page inSection:0]];
    cell.contentView.alpha = 0;
    
    RGIMGalleryTransitionCompletion com = ^(BOOL flag) {
        if (flag) {
            [self __loadStatusWtihResetView:NO];
        } else {
            cell.contentView.alpha = 1;
        }
    };
    
    return com;
}

- (RGIMGalleryTransitionCompletion)imageGallery:(RGImageGallery *)imageGallery willBePushedWithParentViewController:(UIViewController *)viewController {
    
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:imageGallery.page inSection:0]];
    cell.contentView.alpha = 0;
    
    RGIMGalleryTransitionCompletion com = ^(BOOL flag) {
        cell.contentView.alpha = 1;
    };
    return com;
}

#pragma mark - RGImagePickerViewGalleryDelegateTarget

- (void)imagePickerViewGalleryDelegate:(RGImagePickerViewGalleryDelegate *)delegate selectAssetAtIndex:(NSUInteger)index {
    [self __selectItemAtIndex:index orCell:nil];
    [self feedback];
}

#pragma mark - RGImagePickerCachePickPhotosHasChanged

- (void)__imagePickerCachePickPhotosHasChanged:(NSNotification *)noti {
    if (self.navigationController.topViewController != self) {
        [self __configViewWhenCacheChanged];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(__loadStatusWtihResetView:) object:@(NO)];
        [self performSelector:@selector(__loadStatusWtihResetView:) withObject:@(NO) afterDelay:0.6];
    }
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // 预加载区域是可显示区域的两倍
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    // 比较是否显示的区域与之前预加载的区域有不同
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0f) {
        
        // 区分资源分别操作
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self indexPathsForElementsInCollectionView:self.collectionView rect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self indexPathsForElementsInCollectionView:self.collectionView rect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // 更新缓存
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:self.lowThumbSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:requestOptions];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:self.lowThumbSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:requestOptions];
        
        // 存储预加载矩形已供比较
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = self.assets[indexPath.item];
        [assets addObject:asset];
    }
    
    return assets;
}

- (NSArray *)indexPathsFromIndexes:(NSIndexSet *)indexSet section:(NSUInteger)section {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:indexSet.count];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}

- (NSArray *)indexPathsForElementsInCollectionView:(UICollectionView *)collection rect:(CGRect)rect {
    NSArray *allLayoutAttributes = [collection.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

#pragma mark - Pin

- (void)pin:(UIPinchGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:{
            NSIndexPath *path = nil;
            NSUInteger touchCount = gesture.numberOfTouches;
            if (touchCount == 2) {
                CGPoint p1 = [gesture locationOfTouch:0 inView:self.collectionView];
                CGPoint p2 = [gesture locationOfTouch:1 inView:self.collectionView];
                CGPoint center = CGPointMake((p1.x+p2.x)/2,(p1.y+p2.y)/2);
                path = [self.collectionView indexPathForItemAtPoint:center];
            }
            
            if (!path) {
                return;
            }
            
            RGImageGallery *imageGallery = [[RGImageGallery alloc] initWithPlaceHolder:self.config.loadFailedImage andDataSource:self];
            imageGallery.pushTransitionDelegate = self;
            
            self.galleryDelegate.imageGallery = imageGallery;
            
            imageGallery.delegate = self.galleryDelegate;
            imageGallery.additionUIConfig = self.galleryDelegate;
            
            gesture.view.rg_originSize = [self.collectionView cellForItemAtIndexPath:path].frame.size;
            
            imageGallery.pushFromView = YES;
            
            [imageGallery beganInteractionPushAtIndex:path.row fatherViewController:self];
            
            self.imageGallery = imageGallery;
            self.interactionAnimate = YES;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.1 delay:0 options:0 animations:^{
                    NSUInteger touchCount = gesture.numberOfTouches;
                    if (touchCount == 2) {
                        CGPoint p1 = [gesture locationOfTouch:0 inView:self.collectionView];
                        CGPoint p2 = [gesture locationOfTouch:1 inView:self.collectionView];
                        CGSize size = CGSizeMake(fabs(p1.x - p2.x), fabs(p1.y - p2.y));
                        CGPoint center = CGPointMake((p1.x + p2.x) / 2,(p1.y + p2.y) / 2);
                        center = [self.collectionView convertPoint:center toView:self.view];
                        [imageGallery updateInteractionPushCenter:center];
                        [imageGallery updateInteractionPushSize:size];
                    }
                } completion:^(BOOL finished) {
                    self.interactionAnimate = NO;
                    gesture.scale = 1;
                    [self pin:gesture];
                }];
            });
            break;
        }
        case UIGestureRecognizerStateChanged:{
            if (self.interactionAnimate) {
                return;
            }
            NSUInteger touchCount = gesture.numberOfTouches;
            if (touchCount == 2) {
                CGPoint p1 = [gesture locationOfTouch:0 inView:self.collectionView];
                CGPoint p2 = [gesture locationOfTouch:1 inView:self.collectionView];
                CGSize size = CGSizeMake(fabs(p1.x - p2.x), fabs(p1.y - p2.y));
                CGPoint center = CGPointMake((p1.x + p2.x) / 2,(p1.y + p2.y) / 2);
                center = [self.collectionView convertPoint:center toView:self.view];
                [self.imageGallery updateInteractionPushCenter:center];
                [self.imageGallery updateInteractionPushSize:size];
                
                UIView *view = [self.imageGallery interactionPushView];
                CGFloat progress = (view.frame.size.width - gesture.view.rg_originSize.width) / self.view.frame.size.width;
                [self.imageGallery updateInteractionPushProgress:progress];
            }
            break;
        }
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateEnded:{
            if (self.interactionAnimate) {
                return;
            }
            UIView *view = [self.imageGallery interactionPushView];
            CGFloat progress = [self.imageGallery interactionPushProgress];
            if (!progress) {
                progress = (view.frame.size.width - gesture.view.rg_originSize.width) / self.view.frame.size.width;
            }
            [self.imageGallery finishInteractionPush:gesture.scale >= 1 progress:progress];
            break;
        }
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        default:{
            [self.imageGallery finishInteractionPush:NO progress:[self.imageGallery interactionPushProgress]];
            break;
        }
    }
}

@end
