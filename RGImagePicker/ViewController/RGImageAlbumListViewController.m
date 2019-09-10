//
//  CTImageAlbumListViewController.m
//  CampTalk
//
//  Created by renge on 2018/5/7.
//  Copyright © 2018年 yuru. All rights reserved.
//

#import "RGImageAlbumListViewController.h"
#import "RGImagePickerViewController.h"
#import <RGUIKit/RGUIKit.h>

#define RGAlbumListRowHeight 46

@interface RGImageAlbumListViewController () <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) NSMutableArray <PHAssetCollection *> *mCollections;

@end

@implementation RGImageAlbumListViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)loadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        PHFetchOptions *option = self.cache.config.option;
        
        PHImageRequestOptions *loadOp = [[PHImageRequestOptions alloc] init];
        loadOp.synchronous = YES;
        loadOp.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        loadOp.resizeMode = PHImageRequestOptionsResizeModeExact;
        
        NSMutableArray <PHAssetCollection *> *mCollections = [NSMutableArray array];
        
        CGSize size = CGSizeMake(RGAlbumListRowHeight*UIScreen.mainScreen.scale, RGAlbumListRowHeight*UIScreen.mainScreen.scale);
        
        void(^setInfo)(PHAssetCollection *coll, PHFetchResult<PHAsset *> *result) = ^(PHAssetCollection *coll, PHFetchResult<PHAsset *> *result) {
            [coll rg_setValue:@(result.count) forConstKey:"rg_count" retain:NO];
            [coll rg_setValue:@(result.count) forConstKey:"rg_count" retain:NO];
            
            if (result.count <= 0) {
                return;
            }
            [[PHCachingImageManager defaultManager] requestImageForAsset:result.lastObject targetSize:size contentMode:PHImageContentModeAspectFill options:loadOp resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                [coll rg_setValue:result forConstKey:"rg_thumb" retain:YES];
            }];
        };
        
        void(^customCollection)(PHAssetCollectionSubtype type) = ^(PHAssetCollectionSubtype type) {
            PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:type options:nil];
            
            PHAssetCollection *collection = collections.lastObject;
            PHFetchResult<PHAsset *> *asset = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            
            if (collections && asset.count) {
                setInfo(collection, asset);
                [mCollections addObject:collection];
            }
        };
        
        void(^setInfoForCollections)(PHFetchResult<PHAssetCollection *> *album) = ^(PHFetchResult<PHAssetCollection *> *album) {
            [album enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                    return;
                }
                PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsInAssetCollection:obj options:option];
                if (result.count > 0) {
                    setInfo(obj, result);
                    [mCollections addObject:obj];
                }
            }];
        };
        
        if (self.cache.config.cutomSmartAlbum.count) {
            [self.cache.config.cutomSmartAlbum enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                PHAssetCollectionSubtype type = obj.integerValue;
                customCollection(type);
            }];
        } else {
            // 所有照片
            customCollection(PHAssetCollectionSubtypeSmartAlbumUserLibrary);
            
            // 全部智能相册
            PHFetchResult<PHAssetCollection *> *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            setInfoForCollections(smartAlbums);
        }
        
        // 全部用户相册
        PHFetchResult<PHAssetCollection *> *otherAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        setInfoForCollections(otherAlbums);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.mCollections = mCollections;
            if (self.isViewLoaded) {
                [self.tableView reloadData];
            }
        });
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = RGAlbumListRowHeight;
    self.tableView.estimatedRowHeight = 0;
    [self.tableView registerClass:RGIconCell.class forCellReuseIdentifier:RGCellIDValue1];
    
    UIBarButtonItem *down = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(rg_dismiss)];
    self.navigationItem.rightBarButtonItem = down;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.presentingViewController setNeedsStatusBarAppearanceUpdate];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mCollections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RGIconCell *cell = [tableView dequeueReusableCellWithIdentifier:RGCellIDValue1 forIndexPath:indexPath];
    cell.iconSize = CGSizeMake(tableView.rowHeight, tableView.rowHeight);
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    PHAssetCollection *coll = self.mCollections[indexPath.row];
    
    cell.textLabel.text = coll.localizedTitle;
    cell.detailTextLabel.text = [[coll rg_valueforConstKey:"rg_count"] stringValue];
    cell.imageView.image = [coll rg_valueforConstKey:"rg_thumb"];;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PHAssetCollection *collection = self.mCollections[indexPath.row];
    RGImagePickerViewController *albumDetails = [[RGImagePickerViewController alloc] init];
    albumDetails.cache = self.cache;
    albumDetails.collection = collection;
    [self.navigationController pushViewController:albumDetails animated:YES];
}

- (void)callBack {
    [self.cache callBack:self];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    [self loadData];
}

@end
