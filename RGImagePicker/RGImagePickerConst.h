//
//  RGImagePickerConst.h
//  CampTalk
//
//  Created by renge on 2019/8/1.
//  Copyright © 2019 yuru. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "RGImagePickerViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^RGImagePickResult)(NSArray <PHAsset *> *phassets, UIViewController *pickerViewController);

@interface RGImagePickerConfig : NSObject

/// default system Tintcolor
@property (nonatomic, strong, nullable) UIColor *tintColor;

/// NSString or NSAttributedString
@property (nonatomic, copy, nullable) id privacyDescriptionString;

/// default systemBackgroundColor
@property (nonatomic, strong, nullable) UIColor *backgroundColor;
@property (nonatomic, strong, nullable) UIImage *backgroundImage;
@property (nonatomic, assign) CGFloat backgroundBlurRadius;

/// defalut a icon like plane
@property (nonatomic, strong, nullable) UIImage *sendIcon;

/// play video
@property (nonatomic, strong, nullable) UIImage *playIcon;

/// default nil
@property (nonatomic, strong, nullable) UIImage *loadFailedImage;

/// display item option
@property (nonatomic, strong, nullable) PHFetchOptions *option;

/// cutomSmartAlbum @see PHAssetCollectionSubtype, value should big than PHAssetCollectionSubtypeSmartAlbumGeneric
@property (nonatomic, strong, nullable) NSArray <NSNumber *> *cutomSmartAlbum;

/// default PHAssetCollectionSubtypeSmartAlbumUserLibrary
@property (nonatomic, assign) PHAssetCollectionSubtype defaultType;


/**
 pick image config
 */
+ (RGImagePickerConfig *)onlyImageConfig;

@end

NS_ASSUME_NONNULL_END
