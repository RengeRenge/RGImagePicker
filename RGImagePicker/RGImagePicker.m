//
//  RGImagePicker.m
//  CampTalk
//
//  Created by renge on 2019/8/1.
//  Copyright © 2019 yuru. All rights reserved.
//

#import "RGImagePicker.h"
#import "RGImagePickerCache.h"
#import "RGImageAlbumListViewController.h"
#import <RGUIKit/RGUIKit.h>
#import "UIImage+RGPickerIcon.h"

const NSString *RGImagePickerResourceUTI = @"dataUTI";
const NSString *RGImagePickerResourceType = @"type";
const NSString *RGImagePickerResourceFilename = @"filename";
const NSString *RGImagePickerResourceData = @"data";
const NSString *RGImagePickerResourceThumbData = @"thumbData";
const NSString *RGImagePickerResourceSize = @"size";
const NSString *RGImagePickerResourceThumbSize = @"thumbSize";

const NSString *RGImagePickerResourceLivePhotoInstance = @"livePhoto";
const NSString *RGImagePickerResourceAVAssetInstance = @"avssset";

@implementation RGImagePickerConfig

+ (RGImagePickerConfig *)onlyImageConfig {
    RGImagePickerConfig *config = [RGImagePickerConfig new];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.predicate = predicate;
    config.option = option;
    return config;
}

- (UIColor *)backgroundColor {
    if (!_backgroundColor) {
        _backgroundColor =  [UIColor whiteColor];
    }
    return _backgroundColor;
}

- (UIImage *)sendIcon {
    if (!_sendIcon) {
        _sendIcon = [UIImage rg_sendImage];
    }
    return _sendIcon;
}

- (UIImage *)playIcon {
    if (!_playIcon) {
        _playIcon = [UIImage rg_playImage];
    }
    return _playIcon;
}

- (id)privacyDescriptionString {
    if (_privacyDescriptionString) {
        return _privacyDescriptionString;
    }
    return @"App 没有权限访问您的相册\n\n请前往设置 打开权限";
}

@end

@implementation RGImagePicker

+ (UINavigationController *)presentByViewController:(UIViewController *)viewController pickResult:(RGImagePickResult)pickResult {
    return [self presentByViewController:viewController maxCount:1 pickResult:pickResult];
}

+ (UINavigationController *)presentByViewController:(UIViewController *)viewController maxCount:(NSUInteger)maxCount pickResult:(RGImagePickResult)pickResult {
    return [self presentByViewController:viewController maxCount:maxCount config:nil pickResult:pickResult];
}

+ (UINavigationController *)presentByViewController:(UIViewController *)viewController maxCount:(NSUInteger)maxCount config:(nullable RGImagePickerConfig *)config pickResult:(nonnull RGImagePickResult)pickResult {
    UINavigationController *ngc = [self pickerWithMaxCount:maxCount config:config pickResult:pickResult];
    [viewController presentViewController:ngc animated:YES completion:nil];
    return ngc;
}

+ (UINavigationController *)pickerWithMaxCount:(NSUInteger)maxCount config:(RGImagePickerConfig *)config pickResult:(RGImagePickResult)pickResult {
    RGImagePickerCache *cache = [[RGImagePickerCache alloc] init];
    cache.pickResult = pickResult;
    cache.maxCount = maxCount;
    cache.config = config ? config : [RGImagePickerConfig new];
    
    RGImagePickerViewController *vc = [[RGImagePickerViewController alloc] init];
    vc.cache = cache;
    
    void(^loadData)(void) = ^{
        PHAssetCollectionSubtype type = PHAssetCollectionSubtypeSmartAlbumUserLibrary;
        if (cache.config.defaultType >= PHAssetCollectionSubtypeSmartAlbumGeneric) {
            type = cache.config.defaultType;
        }
        PHFetchResult *colls = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:type options:nil];
        vc.collection = colls.firstObject;
    };
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    loadData();
                });
            }
        }];
    } else {
        loadData();
    }
    
    RGImageAlbumListViewController *list = [[RGImageAlbumListViewController alloc] initWithStyle:UITableViewStylePlain];
    list.pickResult = pickResult;
    list.cache = cache;
    [list loadData];
    
    RGNavigationController *nvg = [RGNavigationController navigationWithRoot:list style:RGNavigationBackgroundStyleNormal];
    [nvg setViewControllers:@[list, vc] animated:NO];
    nvg.modalPresentationStyle = UIModalPresentationOverFullScreen;
    nvg.tintColor = cache.config.tintColor;
    nvg.titleColor = [UIColor blackColor];
    
    UIBarButtonItem *camera = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:nil action:nil];
    list.navigationItem.backBarButtonItem = camera;
    
    return nvg;
}

#pragma mark - Display Image Api

+ (void)needLoadWithAsset:(PHAsset *)asset result:(void (^)(BOOL))result {
    void(^oldMethod)(void) = ^{
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = NO;
        options.synchronous = NO;
        
        CGSize orSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
        
        __block BOOL needLoad = NO;
        [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:orSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
            BOOL isLoaded = ![info[PHImageResultIsDegradedKey] boolValue] && image;
            needLoad = !isLoaded;
            if (result) {
                result(needLoad);
            }
        }];
    };
    
    if (@available(iOS 9.0, *)) {
        if (asset.rg_isLive) {
            if (@available(iOS 9.1, *)) {
                [self __loadLivePhotoFromAsset:asset networkAccessAllowed:NO needStaticImage:NO progressHandler:nil completion:^(NSDictionary * _Nullable resource, NSError * _Nullable error) {
                    if (result) {
                        BOOL hasData = resource[RGImagePickerResourceLivePhotoInstance] != nil;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            BOOL needLoad = error || !hasData;
                            result(needLoad);
                        });
                    }
                }];
                return;
            }
        }
        
        NSArray<PHAssetResource *> * resources = [PHAssetResource assetResourcesForAsset:asset];
        PHAssetResource *resource = nil;
        for (NSInteger i = resources.count - 1; i >= 0; i--) {
            PHAssetResource *obj = resources[i];
            if (![self isPhoto:obj] && ![self isVideo:obj]) {
                continue;
            }
            if ([self isGIF:obj]) {
                resource = obj;
                break;
            }
        }
        if (resource) {
            PHAssetResourceRequestOptions *option = [[PHAssetResourceRequestOptions alloc] init];
            option.networkAccessAllowed = NO;
            
            __block BOOL hasData = NO;
            [[PHAssetResourceManager defaultManager] requestDataForAssetResource:resource options:option dataReceivedHandler:^(NSData * _Nonnull data) {
                hasData |= data.length > 0;
            } completionHandler:^(NSError * _Nullable error) {
                if (result) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        BOOL needLoad = error || !hasData;
                        result(needLoad);
                    });
                }
            }];
        } else {
            oldMethod();
        }
    } else {
        oldMethod();
    }
}

+ (void)imageForAsset:(PHAsset *)asset
             syncLoad:(BOOL)syncLoad
             allowNet:(BOOL)allowNet
           targetSize:(CGSize)targetSize
           resizeMode:(PHImageRequestOptionsResizeMode)resizeMode
            needImage:(BOOL)needImage
           completion:(void(^_Nullable)(id image))completion {
    
    PHImageRequestOptions *op = [[PHImageRequestOptions alloc] init];
    op.resizeMode = resizeMode;
    op.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    op.synchronous = syncLoad;
    op.networkAccessAllowed = allowNet;
    
    if (needImage) {
        [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:op resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (completion) {
                completion(result);
            }
        }];
    } else {
        [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset options:op resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            if (completion) {
                completion(imageData);
            }
        }];
    }
}

#pragma mark - Load Resource Method

+ (NSInteger)loadResourceFromAsset:(PHAsset *)asset
                        loadOption:(RGImagePickerLoadOption)loadOption
                   progressHandler:(void (^ _Nullable)(double))progressHandler
                        completion:(RGImagePickerResult)completion {
    return [self __loadResourceFromAsset:asset loadOption:loadOption networkAccessAllowed:YES progressHandler:progressHandler completion:completion];
}

+ (NSInteger)__loadResourceFromAsset:(PHAsset *)asset
                        loadOption:(RGImagePickerLoadOption)loadOption
              networkAccessAllowed:(BOOL)networkAccessAllowed
                   progressHandler:(void (^ _Nullable)(double))progressHandler
                          completion:(RGImagePickerResult)completion {
    if (loadOption == 0) {
        loadOption = RGImagePickerLoadVideoFirst;
    }
    
    void(^callBackIfNeed)(NSDictionary *resource, NSError *error) = ^(NSDictionary *resource, NSError *error) {
        if (completion && (resource.count || error)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(resource, error);
            });
        }
    };
    
    if (@available(iOS 9.0, *)) {
        NSArray<PHAssetResource *> * resources = [PHAssetResource assetResourcesForAsset:asset];
        if (!resources.count) {
            return [self __loadImageOrVideoFromAsset:asset loadOption:loadOption networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
        }
        BOOL isVideo = !asset.rg_isImage;
        
        if (isVideo) {
            return [self __loadImageOrVideoFromAsset:asset loadOption:loadOption networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
        } else {
            if ((loadOption & RGImagePickerLoadVideoFirst) ||
                (loadOption & RGImagePickerLoadOnlyImage)) {
                if (asset.rg_isLive && (loadOption & RGImagePickerLoadNeedLivePhoto)) {
                    if (@available(iOS 9.1, *)) {
                        return [self __loadLivePhotoFromAsset:asset networkAccessAllowed:networkAccessAllowed needStaticImage:YES progressHandler:progressHandler completion:completion];
                    }
                    return [self __loadImageOrVideoFromAsset:asset loadOption:RGImagePickerLoadOnlyImage networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
                }
                
                // load image, GIF need use PHAssetResourceManager
                PHAssetResource *resource = nil;
                for (NSInteger i = resources.count - 1; i >= 0; i--) {
                    PHAssetResource *obj = resources[i];
                    if (![self isPhoto:obj]) {
                        continue;
                    }
                    resource = obj;
                    break;
                }
                
                if (!resource) {
                    return [self __loadImageOrVideoFromAsset:asset loadOption:loadOption networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
                }
                
                PHAssetResourceRequestOptions *option = [[PHAssetResourceRequestOptions alloc] init];
                option.networkAccessAllowed = networkAccessAllowed;
                
                option.progressHandler = ^(double progress) {
                    if (progressHandler) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            asset.rgLoadLargeImageProgress = progress;
                            progressHandler(progress);
                        });
                    }
                };
                
                NSMutableData *imageData = [NSMutableData data];
                return [[PHAssetResourceManager defaultManager] requestDataForAssetResource:resource options:option dataReceivedHandler:^(NSData * _Nonnull data) {
                    [imageData appendData:data];
                } completionHandler:^(NSError * _Nullable error) {
                    CGSize size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
                    RGImagePickerResourceDataType type = isVideo ? RGImagePickerResourceDataTypeVideo : RGImagePickerResourceDataTypeImage;
                    callBackIfNeed(@{
                                     RGImagePickerResourceData: imageData,
                                     RGImagePickerResourceSize: NSStringFromCGSize(size),
                                     RGImagePickerResourceUTI: resource.uniformTypeIdentifier,
                                     RGImagePickerResourceFilename: resource.originalFilename,
                                     RGImagePickerResourceType: @(type)
                                     }, error);
                }];
            }
        }
    } else {
        return [self __loadImageOrVideoFromAsset:asset loadOption:loadOption networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
    }
    return -1;
}

+ (NSInteger)__loadImageOrVideoFromAsset:(PHAsset *)asset
                            loadOption:(RGImagePickerLoadOption)loadOption
                  networkAccessAllowed:(BOOL)networkAccessAllowed
                       progressHandler:(void(^_Nullable)(double progress))progressHandler
                            completion:(RGImagePickerResult)completion {
    if (loadOption == 0) {
        loadOption = RGImagePickerLoadVideoFirst;
    }
    
    BOOL isVideo = !asset.rg_isImage;
    
    if (loadOption & RGImagePickerLoadOnlyImage) {
        return [self loadImageFromAsset:asset loadOption:loadOption networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
    }
    if (loadOption & RGImagePickerLoadOnlyVideo && isVideo) {
        return [self loadVideoFromAsset:asset loadOption:loadOption networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
    }
    if (loadOption & RGImagePickerLoadVideoFirst) {
        if (isVideo) {
            return [self loadVideoFromAsset:asset loadOption:loadOption networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
        }
        return [self loadImageFromAsset:asset loadOption:loadOption networkAccessAllowed:networkAccessAllowed progressHandler:progressHandler completion:completion];
    }
    if (completion) {
        completion(nil, nil);
    }
    return -1;
}

+ (NSInteger)loadImageFromAsset:(PHAsset *)asset
                     loadOption:(RGImagePickerLoadOption)loadOption
           networkAccessAllowed:(BOOL)networkAccessAllowed
                progressHandler:(void (^ _Nullable)(double))progressHandler
                     completion:(RGImagePickerResult)completion {
    if (loadOption & RGImagePickerLoadNeedLivePhoto && asset.rg_isLive) {
        if (@available(iOS 9.1, *)) {
            return [self __loadLivePhotoFromAsset:asset networkAccessAllowed:networkAccessAllowed needStaticImage:YES progressHandler:progressHandler completion:completion];
        }
    }
    
    void(^callBackIfNeed)(NSDictionary *resource, NSError *error) = ^(NSDictionary *resource, NSError *error) {
        if (completion && (resource.count || error)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(resource, error);
            });
        }
    };
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.networkAccessAllowed = networkAccessAllowed;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                asset.rgLoadLargeImageProgress = progress;
                progressHandler(progress);
            });
        }
        if (error) {
            callBackIfNeed(nil, error);
        }
    };
    
    NSInteger reqId = [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (!imageData) {
            return;
        }
        
        NSURL *path = info[@"PHImageFileURLKey"];
        NSString *filename = @"";
        if (path) {
            filename = path.lastPathComponent;
        } else {
            filename = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:dataUTI.pathExtension];
        }
        CGSize size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
        callBackIfNeed(@{
                         RGImagePickerResourceData: imageData,
                         RGImagePickerResourceSize: NSStringFromCGSize(size),
                         RGImagePickerResourceUTI: dataUTI,
                         RGImagePickerResourceFilename: filename,
                         RGImagePickerResourceType: @(RGImagePickerResourceDataTypeImage)
                         }, nil);
    }];
    return reqId;
}

+ (NSInteger)loadVideoFromAsset:(PHAsset *)asset
                     loadOption:(RGImagePickerLoadOption)loadOption
           networkAccessAllowed:(BOOL)networkAccessAllowed
                progressHandler:(void (^ _Nullable)(double))progressHandler
                     completion:(RGImagePickerResult)completion {
    void(^callBackIfNeed)(NSDictionary *resource, NSError *error) = ^(NSDictionary *resource, NSError *error) {
        if (completion && (resource.count || error)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(resource, error);
            });
        }
    };
    
    PHVideoRequestOptions *op = [[PHVideoRequestOptions alloc] init];
    op.networkAccessAllowed = networkAccessAllowed;
    PHVideoRequestOptionsDeliveryMode mode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
    if (loadOption & RGImagePickerLoadVideoAutoQuality) {
        mode = PHVideoRequestOptionsDeliveryModeAutomatic;
    } else if (loadOption & RGImagePickerLoadVideoHighQuality) {
        mode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    } else if (loadOption & RGImagePickerLoadVideoMediumQuality) {
        mode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
    } else if (loadOption & RGImagePickerLoadVideoLowQuality) {
        mode = PHVideoRequestOptionsDeliveryModeFastFormat;
    }
    op.deliveryMode = mode;
    op.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                asset.rgLoadLargeImageProgress = progress;
                progressHandler(progress);
            });
        }
        if (error) {
            callBackIfNeed(nil, error);
        }
    };
    
    NSInteger reqId = [[PHCachingImageManager defaultManager] requestAVAssetForVideo:asset options:op resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (!avAsset) {
            return;
        }
        
        CGSize size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
        
        void(^doCallBack)(NSData *data, NSURL *url) = ^(NSData *data, NSURL *url) {
            callBackIfNeed(@{
                             RGImagePickerResourceData: data,
                             RGImagePickerResourceType: @(RGImagePickerResourceDataTypeVideo),
                             RGImagePickerResourceAVAssetInstance: avAsset,
                             RGImagePickerResourceSize: NSStringFromCGSize(size),
//                             RGImagePickerResourceType: dataUTI,
                             RGImagePickerResourceFilename: url.lastPathComponent,
                             }, nil);
        };
        
        if ([avAsset isKindOfClass:AVURLAsset.class]) {
            AVURLAsset *urlAsset = (AVURLAsset *)avAsset;
            NSURL *url = urlAsset.URL;
            NSData *data = [NSData dataWithContentsOfURL:url];
            doCallBack(data, url);
        } else { // 比如慢动作视频 AVComposition
            [self __convertAvcomposition:avAsset localIdentifier:asset.localIdentifier completion:^(NSData *data, NSURL *url, NSError *error) {
                if (data && url) {
                    doCallBack(data, url);
                } else {
                    callBackIfNeed(nil, error);
                }
            }];
        }
    }];
    return reqId;
}

+ (NSInteger)loadLivePhotoFromAsset:(PHAsset *)asset
               networkAccessAllowed:(BOOL)networkAccessAllowed
                    progressHandler:(void (^)(double))progressHandler
                         completion:(RGImagePickerResult)completion API_AVAILABLE(ios(9.1)) {
    return [self __loadLivePhotoFromAsset:asset networkAccessAllowed:YES needStaticImage:YES progressHandler:progressHandler completion:completion];
}

+ (NSInteger)__loadLivePhotoFromAsset:(PHAsset *)asset
                 networkAccessAllowed:(BOOL)networkAccessAllowed
                      needStaticImage:(BOOL)needStaticImage
                      progressHandler:(void (^)(double))progressHandler
                           completion:(RGImagePickerResult)completion API_AVAILABLE(ios(9.1)) {
    void(^callBackIfNeed)(NSDictionary *resource, NSError *error) = ^(NSDictionary *resource, NSError *error) {
        if (completion && (resource.count || error)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(resource, error);
            });
        }
    };
    
    PHCachingImageManager *manager = (PHCachingImageManager *)[PHCachingImageManager defaultManager];
    PHLivePhotoRequestOptions *op = [[PHLivePhotoRequestOptions alloc] init];
    op.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    op.networkAccessAllowed = networkAccessAllowed;
    op.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (progressHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                asset.rgLoadLargeImageProgress = progress;
                progressHandler(progress);
            });
        }
    };
    
    CGSize size = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    return [manager requestLivePhotoForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:op resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        NSDictionary *returnInfo;
        if (livePhoto) {
            returnInfo = @{
                           RGImagePickerResourceLivePhotoInstance: livePhoto,
                           RGImagePickerResourceSize: NSStringFromCGSize(size)
                           };
            
            if (needStaticImage) {
                [self __loadResourceFromAsset:asset loadOption:RGImagePickerLoadOnlyImage
                         networkAccessAllowed:networkAccessAllowed progressHandler:nil completion:^(NSDictionary * _Nullable resource, NSError * _Nullable error) {
                    NSMutableDictionary *combine = [NSMutableDictionary dictionaryWithDictionary:returnInfo];
                    if (resource) {
                        [combine addEntriesFromDictionary:resource];
                    }
                    callBackIfNeed(combine, error);
                }];
            } else {
                callBackIfNeed(returnInfo, nil);
            }
        } else {
            callBackIfNeed(nil, [NSError errorWithDomain:@"PHImageResultIsInCloudKey" code:0 userInfo:@{PHImageResultIsInCloudKey: @(1)}]);
        }
    }];
}

+ (void)cancelLoadResourceWithRequestId:(NSInteger)requestId {
    if (@available(iOS 9.0, *)) {
        [[PHAssetResourceManager defaultManager] cancelDataRequest:(int)requestId];
    }
    [[PHCachingImageManager defaultManager] cancelImageRequest:(int)requestId];
}

#pragma mark - Multi-Load Resource Method

+ (void)loadResourceFromAssets:(NSArray<PHAsset *> *)assets
                    loadOption:(RGImagePickerLoadOption)loadOption
                    completion:(nonnull void (^)(NSArray<NSDictionary *> * _Nonnull, NSError * _Nullable))completion {
    [self loadResourceFromAssets:assets loadOption:loadOption thumbSize:CGSizeZero completion:completion];
}

+ (void)loadResourceFromAssets:(NSArray<PHAsset *> *)assets
                    loadOption:(RGImagePickerLoadOption)loadOption
                     thumbSize:(CGSize)thumbSize
                    completion:(void (^)(NSArray<NSDictionary *> * _Nonnull, NSError * _Nullable))completion {
    if (assets.count == 0) {
        if (completion) {
            completion(@[], nil);
        }
    }
    
    NSMutableArray <NSDictionary *> *array = [NSMutableArray arrayWithCapacity:assets.count];
    for (int i = 0; i < assets.count; i++) {
        [array addObject:@{}];
    }
    
    __block NSInteger count = assets.count;
    
    void(^callBackIfNeed)(NSError *error) = ^(NSError *error) {
        count--;
        if ((count == 0 || error) && completion) {
            count = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(array, error);
            });
        }
    };
    
    [assets enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self loadResourceFromAsset:obj loadOption:loadOption progressHandler:nil completion:^(NSDictionary * _Nullable resource, NSError * _Nullable error) {
            
            if (error) {
                callBackIfNeed(error);
                return;
            }
            
            if ([resource[RGImagePickerResourceData] length]) {
                if (!CGSizeEqualToSize(thumbSize, CGSizeZero)) {
                    [self imageForAsset:obj syncLoad:NO allowNet:YES targetSize:thumbSize resizeMode:PHImageRequestOptionsResizeModeExact needImage:NO completion:^(NSData *thumbData) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            NSMutableDictionary *newResource = [NSMutableDictionary dictionaryWithDictionary:resource];
                            
                            UIImage *thumbImage = [UIImage imageWithData:thumbData];
                            NSData *smallData = UIImageJPEGRepresentation(thumbImage, 0.5);
                            if (smallData.length > thumbData.length) {
                                smallData = thumbData;
                            } else {
                                thumbImage = [UIImage imageWithData:smallData];
                            }
                            newResource[RGImagePickerResourceThumbData] = smallData;
                            newResource[RGImagePickerResourceThumbSize] = NSStringFromCGSize(thumbImage.rg_pixSize);
                            [array replaceObjectAtIndex:idx withObject:newResource];
                            callBackIfNeed(error);
                        });
                    }];
                } else {
                    [array replaceObjectAtIndex:idx withObject:resource];
                    callBackIfNeed(error);
                }
            } else {
                callBackIfNeed(error);
            }
        }];
    }];
}

#pragma mark - Private

+ (BOOL)isVideo:(PHAssetResource *)resource  API_AVAILABLE(ios(9.0)) {
    switch (resource.type) {
        case PHAssetResourceTypeVideo:
        case PHAssetResourceTypeAudio:
        case PHAssetResourceTypeFullSizeVideo:
        case PHAssetResourceTypePairedVideo:
        case PHAssetResourceTypeFullSizePairedVideo:
        case PHAssetResourceTypeAdjustmentBasePairedVideo:
            return YES;
        default:
            return NO;
    }
}

+ (BOOL)isPhoto:(PHAssetResource *)resource  API_AVAILABLE(ios(9.0)) {
    switch (resource.type) {
        case PHAssetResourceTypeFullSizePhoto:
        case PHAssetResourceTypePhoto:
        case PHAssetResourceTypeAlternatePhoto:
        case PHAssetResourceTypeAdjustmentBasePhoto:
            return YES;
        default:
            return NO;
    }
}

+ (BOOL)isGIF:(PHAssetResource *)resource  API_AVAILABLE(ios(9.0)) {
    if ([resource.uniformTypeIdentifier hasSuffix:@".gif"] || [resource.uniformTypeIdentifier hasSuffix:@".GIF"]) {
        return YES;
    }
    
    if ([resource.originalFilename hasSuffix:@".gif"] || [resource.originalFilename hasSuffix:@".GIF"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isPNG:(PHAssetResource *)resource  API_AVAILABLE(ios(9.0)) {
    if ([resource.uniformTypeIdentifier hasSuffix:@".png"] || [resource.uniformTypeIdentifier hasSuffix:@".PNG"]) {
        return YES;
    }
    
    if ([resource.originalFilename hasSuffix:@".png"] || [resource.originalFilename hasSuffix:@".PNG"]) {
        return YES;
    }
    return NO;
}

+ (void)__convertAvcomposition:(AVAsset *)composition localIdentifier:(NSString *)localIdentifier completion:(void (^)(NSData *data, NSURL *url, NSError *error))completion {
    
    // https://stackoverflow.com/questions/26152396/how-to-access-nsdata-nsurl-of-slow-motion-videos-using-photokit
    
    localIdentifier = [localIdentifier componentsSeparatedByString:@"/"].firstObject;
    NSString *basePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *exportPath = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"RGImagePicker/%@.mov", localIdentifier]];
    NSString *directory = [exportPath stringByDeletingLastPathComponent];
    
    NSError *error = nil;
    if (![NSFileManager.defaultManager fileExistsAtPath:directory]) {
        [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    // 导出视频
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    if (!error && exporter) {
        
        [NSFileManager.defaultManager removeItemAtPath:exportPath error:NULL];
        
        NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
        exporter.outputURL = exportURL;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            NSURL *URL = exporter.outputURL;
            NSData *data = [NSData dataWithContentsOfURL:URL];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (AVAssetExportSessionStatusCompleted == exporter.status) {   // 导出完成
                    if (completion) {
                        completion(data, URL, nil);
                    }
                } else {
                    if (completion) {
                        completion(nil, nil, exporter.error);
                    }
                }
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, nil, error);
            }
        });
    }
}

@end
