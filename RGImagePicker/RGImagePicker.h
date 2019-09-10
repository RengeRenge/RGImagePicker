//
//  RGImagePicker.h
//  CampTalk
//
//  Created by renge on 2019/8/1.
//  Copyright © 2019 yuru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RGImagePickerConst.h"

//! Project version number for RGImagePicker.
FOUNDATION_EXPORT double RGImagePickerVersionNumber;

//! Project version string for RGImagePicker.
FOUNDATION_EXPORT const unsigned char RGImagePickerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <RGImagePicker/PublicHeader.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *RGImagePickerResourceUTI; // maybe nil
extern NSString *RGImagePickerResourceFilename;

extern NSString *RGImagePickerResourceData; // resource data
extern NSString *RGImagePickerResourceType; // @see RGImagePickerResourceDataType

extern NSString *RGImagePickerResourceSize;
extern NSString *RGImagePickerResourceThumbSize;
extern NSString *RGImagePickerResourceThumbData;

extern NSString *RGImagePickerResourceLivePhotoInstance; // maybe nil
extern NSString *RGImagePickerResourceAVAssetInstance; // maybe nil

typedef enum : NSUInteger {
    RGImagePickerLoadVideoFirst = 1<<1, // load video if existed else image. default.
    RGImagePickerLoadOnlyImage = 1<<2,
    RGImagePickerLoadOnlyVideo = 1<<3,
    
    // image option
    RGImagePickerLoadNeedLivePhoto = 1<<4,
    
    // video option
    RGImagePickerLoadVideoAutoQuality = 1 << 10, // auto quality
    RGImagePickerLoadVideoHighQuality = 1 << 11, // best quality
    RGImagePickerLoadVideoMediumQuality = 1 << 12, // medium quality (typ. 720p). default.
    RGImagePickerLoadVideoLowQuality = 1 << 13, // low quality (typ. 360p)
} RGImagePickerLoadOption;

typedef enum : NSUInteger {
    RGImagePickerResourceDataTypeImage,
    RGImagePickerResourceDataTypeVideo,
} RGImagePickerResourceDataType;

typedef void(^_Nullable RGImagePickerResult)(NSDictionary *_Nullable resource, NSError *_Nullable error);

@interface RGImagePicker : NSObject

#pragma mark - Display Picker

+ (__kindof UINavigationController *)pickerWithMaxCount:(NSUInteger)maxCount
                                                 config:(nullable RGImagePickerConfig *)config
                                             pickResult:(RGImagePickResult)pickResult;

+ (__kindof UINavigationController *)presentByViewController:(UIViewController *)viewController pickResult:(RGImagePickResult)pickResult;

+ (__kindof UINavigationController *)presentByViewController:(UIViewController *)viewController maxCount:(NSUInteger)maxCount pickResult:(RGImagePickResult)pickResult;

+ (__kindof UINavigationController *)presentByViewController:(UIViewController *)viewController
                                                    maxCount:(NSUInteger)maxCount
                                                      config:(nullable RGImagePickerConfig *)config
                                                  pickResult:(RGImagePickResult)pickResult;

#pragma mark - Display Image Api

/**
 Whether image is in iCloud, this method only for image
 */
+ (void)needLoadWithAsset:(PHAsset *)asset result:(void(^)(BOOL needLoad))result;


/**
 Load Thumbnail
 */
+ (void)imageForAsset:(PHAsset *)asset
             syncLoad:(BOOL)syncLoad
             allowNet:(BOOL)allowNet
           targetSize:(CGSize)targetSize
           resizeMode:(PHImageRequestOptionsResizeMode)resizeMode
            needImage:(BOOL)needImage
           completion:(void(^_Nullable)(id image))completion;

#pragma mark - Load Resource Method

+ (NSInteger)loadResourceFromAsset:(PHAsset *)asset
                        loadOption:(RGImagePickerLoadOption)loadOption
                   progressHandler:(void(^_Nullable)(double progress))progressHandler
                        completion:(RGImagePickerResult)completion;

+ (NSInteger)loadImageFromAsset:(PHAsset *)asset
                     loadOption:(RGImagePickerLoadOption)loadOption
           networkAccessAllowed:(BOOL)networkAccessAllowed
                progressHandler:(void(^_Nullable)(double progress))progressHandler
                     completion:(RGImagePickerResult)completion;

+ (NSInteger)loadVideoFromAsset:(PHAsset *)asset
                     loadOption:(RGImagePickerLoadOption)loadOption
           networkAccessAllowed:(BOOL)networkAccessAllowed
                progressHandler:(void(^_Nullable)(double progress))progressHandler
                     completion:(RGImagePickerResult)completion;

+ (NSInteger)loadLivePhotoFromAsset:(PHAsset *)asset
               networkAccessAllowed:(BOOL)networkAccessAllowed
                    progressHandler:(void(^_Nullable)(double progress))progressHandler
                         completion:(RGImagePickerResult)completion API_AVAILABLE(ios(9.1));

+ (void)cancelLoadResourceWithRequestId:(NSInteger)requestId;


#pragma mark - Multi-Load Resource Method


/**
 load resource from assets
 
 @param assets Some assets
 @param loadOption Which type need to load
 @param thumbSize Need load thumbnail if pass size large than CGSizeZero
 @param completion Resource completion
 */
+ (void)loadResourceFromAssets:(NSArray <PHAsset *> *)assets
                    loadOption:(RGImagePickerLoadOption)loadOption
                     thumbSize:(CGSize)thumbSize
                    completion:(void(^)(NSArray <NSDictionary *> *resource, NSError *_Nullable error))completion;

+ (void)loadResourceFromAssets:(NSArray <PHAsset *> *)assets
                    loadOption:(RGImagePickerLoadOption)loadOption
                    completion:(void(^)(NSArray <NSDictionary *> *resource, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
