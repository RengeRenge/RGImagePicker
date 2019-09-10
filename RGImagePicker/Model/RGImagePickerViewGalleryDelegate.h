//
//  RGImagePickerViewGalleryDelegate.h
//  CampTalk
//
//  Created by renge on 2019/9/5.
//  Copyright © 2019 yuru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <RGUIKit/RGUIKit.h>
#import <PhotosUI/PHLivePhotoView.h>
#import <RGImageGallery/RGImageGallery.h>
#import "RGImagePicker.h"
#import "RGImagePickerCache.h"

NS_ASSUME_NONNULL_BEGIN

@protocol RGImagePickerViewGalleryDelegateTarget;

@interface RGImagePickerViewGalleryDelegate : NSObject <RGImageGalleryDelegate, RGImageGalleryAdditionUIConfig>

@property (nonatomic, weak) RGImageGallery *imageGallery;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) RGImagePickerCache *cache;

@property (nonatomic, strong) PHFetchResult <PHAsset *> *assets;

@property (nonatomic, weak) id<RGImagePickerViewGalleryDelegateTarget> target;
@property (nonatomic, assign) BOOL toolBarModePreview;

- (NSArray <UIBarButtonItem *> *)toolBarItemForGallery:(BOOL)forGallery;

@end

@protocol RGImagePickerViewGalleryDelegateTarget <NSObject>

@optional

- (void)imagePickerViewGalleryDelegate:(RGImagePickerViewGalleryDelegate *)delegate selectAssetAtIndex:(NSUInteger)index;

- (NSArray <UIBarButtonItem *> *)customToolBarItemsAtIndex:(NSUInteger)index forImagePickerViewGalleryDelegate:(RGImagePickerViewGalleryDelegate *)delegate;

@end

NS_ASSUME_NONNULL_END
