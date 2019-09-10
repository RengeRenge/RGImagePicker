//
//  CTImagePickerCell.h
//  CampTalk
//
//  Created by renge on 2019/8/2.
//  Copyright © 2019 yuru. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RGImagePickerConst.h"
#import "RGImagePickerCache.h"

NS_ASSUME_NONNULL_BEGIN

@class RGImagePickerCell;

@protocol RGImagePickerCellDelegate <NSObject>

- (void)imagePickerCell:(RGImagePickerCell *)cell touchForce:(CGFloat)force maximumPossibleForce:(CGFloat)maximumPossibleForce;

- (void)didCheckForImagePickerCell:(RGImagePickerCell *)cell;

@end

@interface RGImagePickerCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *imageViewMask;

@property (nonatomic, strong) RGImagePickerCache *cache;
@property (nonatomic, strong, nullable) PHAsset *asset;

@property (nonatomic, assign) PHImageRequestID lastRequestId;

@property (nonatomic, strong) CAShapeLayer *checkMarkLayer;
@property (nonatomic, strong) CAShapeLayer *selectedLayer;
@property (nonatomic, strong) UIButton *selectedButton;

@property (nonatomic, strong) CALayer *timeLayer;

@property (nonatomic, weak) id <RGImagePickerCellDelegate> delegate;
@property (nonatomic, assign) CGFloat lastTouchForce;

+ (void)loadOriginalWithAsset:(PHAsset *)asset
                        cache:(RGImagePickerCache *)cache
                   updateCell:(RGImagePickerCell * _Nullable)cell
               collectionView:(UICollectionView * _Nullable)collectionView
              progressHandler:(void(^_Nullable)(double progress))progressHandler
                   completion:(void (^_Nullable)(NSData *_Nullable imageData, NSError *_Nullable error))completion;

- (void)setAsset:(PHAsset *)asset
    photoManager:(PHCachingImageManager *)manager
         options:(PHImageRequestOptions *)options
      targetSize:(CGSize)targetSize
           cache:(RGImagePickerCache *)cache
            sync:(BOOL)sync
      loadStatus:(BOOL)loadStatus
       resetView:(BOOL)resetView;

- (BOOL)isCurrentAsset:(PHAsset *)asset;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
