# RGImagePicker

RGImagePicker is a component which could help you elegantly pick image, gif, video and LivePhoto 

## Ability
- Transition animations and interaction gestures like system "Photos" app. Presentation at [RGImageGallery](https://github.com/RengeRenge/RGImageGallery)

- Pick Image
- Long Tap for Displaying presentingViewController

  ![ab_image](https://user-images.githubusercontent.com/14158970/64654644-72d2ad00-d45c-11e9-8080-5e460f0b8289.png)

- Pick GIF

	![ab_gif](https://user-images.githubusercontent.com/14158970/64630043-dd68f600-d426-11e9-9175-9bdd2da03295.png)

- Pick Video

  ![ab_video](https://user-images.githubusercontent.com/14158970/64654711-aca3b380-d45c-11e9-9e5b-d79b60e91b38.gif)

- Pick LivePhoto

  ![ab_live](https://user-images.githubusercontent.com/14158970/64654762-d0ff9000-d45c-11e9-8165-c1cf5d039b92.gif)

- iCloud Support

  ![ab_icloud](https://user-images.githubusercontent.com/14158970/64655072-b4b02300-d45d-11e9-98b8-2fd1725e0c60.gif)

- High Performance When Quickly Slide (There are 16000 photos in presentation)

  ![ab_high](https://user-images.githubusercontent.com/14158970/64654893-1de36680-d45d-11e9-9ab4-1e2b730ec99e.gif)
  
  FPS Infomation
  ![ab_fps](https://user-images.githubusercontent.com/14158970/64654882-1623c200-d45d-11e9-8465-622abb0794a4.jpg)

- Customizable pick resource type
  
- Customizable picker UI
  
  
## Installation
Add via [CocoaPods](http://cocoapods.org) by adding this to your Podfile:

```ruby
pod 'RGImagePicker'
```

## Usage
### Import
```objective-c
#import <RGImagePicker/RGImagePicker.h>
```

### Create a PickerConfig
```objective-c
+ (RGImagePickerConfig *)onlyImageConfigWithBackgroundImage:(UIImage *)backgroundImage {
    RGImagePickerConfig *config = [RGImagePickerConfig new];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", PHAssetMediaTypeImage];
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.predicate = predicate;
    config.option = option;
    
    config.backgroundImage = backgroundImage;
    config.backgroundBlurRadius = 3.5;
    config.tintColor = [UIColor blackColor];
    
    config.privacyDescriptionString = @"App 没有权限访问您的相册\n\n请前往设置 打开权限";
    
    /*
    // Cutom smart album list if need
    NSMutableArray *array = [NSMutableArray array];
    
    [array addObject:@(PHAssetCollectionSubtypeSmartAlbumUserLibrary)];
    [array addObject:@(PHAssetCollectionSubtypeSmartAlbumFavorites)];
    [array addObject:@(PHAssetCollectionSubtypeSmartAlbumTimelapses)];
    [array addObject:@(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded)];
    if (@available(iOS 10.3, *)) {
        [array addObject:@(PHAssetCollectionSubtypeSmartAlbumLivePhotos)];
    }
    [array addObject:@(PHAssetCollectionSubtypeSmartAlbumPanoramas)];
    
    if (@available(iOS 9.0, *)) {
        [array addObject:@(PHAssetCollectionSubtypeSmartAlbumSelfPortraits)];
    }
    config.cutomSmartAlbum = array;
    
    // Push into this album at first
    config.defaultType = PHAssetCollectionSubtypeSmartAlbumFavorites;
    */
    
    return config;
}
```

### Present a Picker
```objective-c
RGImagePickerConfig *config = [self onlyImageConfigWithBackgroundImage:self.backgroundView.image];
[RGImagePicker presentByViewController:self maxCount:10 config:config pickResult:^(NSArray<PHAsset *> * _Nonnull phassets, UIViewController * _Nonnull pickerViewController) {
  // Began multi load resource
}];
```

### Load Resource
```objective-c
// LoadOption tell picker load rules
RGImagePickerLoadOption option = RGImagePickerLoadVideoFirst|RGImagePickerLoadVideoMediumQuality|RGImagePickerLoadNeedLivePhoto;
[RGImagePicker loadResourceFromAssets:phassets
                           loadOption:option
                            thumbSize:CGSizeMake(1280, 1280)
                           completion:^(NSArray<NSDictionary *> * _Nonnull infos, NSError * _Nullable error) {
                               if (error) {
                                   return;
                               }
                               // Handle resource data
                               // 🙋 There is a example from the demo that Presentation in above GIF
                               [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                                   [infos enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull info, NSUInteger idx, BOOL * _Nonnull stop) {
                                       // get resource in info
                                       NSData *imageData = info[RGImagePickerResourceData];
                                       NSData *thumbData = info[RGImagePickerResourceThumbData];
                                       if (!imageData.length) {
                                           return;
                                       }
                                       if (!thumbData.length) {
                                           thumbData = imageData;
                                       }
                                       
                                       PHAsset *asset = phassets[idx];
                                       
                                       NSString *filename = info[RGImagePickerResourceFilename];
                                       NSString *thumbName = nil;
                                       BOOL isGif = [[info[RGImagePickerResourceUTI] lowercaseString] containsString:@"gif"];
                                       if (isGif) {
                                           thumbName = [asset.localIdentifier stringByAppendingPathComponent:filename];
                                           thumbData = imageData;
                                       } else {
                                           thumbName = [asset.localIdentifier stringByAppendingPathComponent:[NSString stringWithFormat:@"thumb-%@", filename]];
                                       }
                                       
                                       // construct message model
                                       RGMessage *model = [RGMessage new];
                                       
                                       // write data to path
                                       NSString *path = [CTFileManger.cacheManager createFile:thumbName atFolder:UCChatDataFolderName data:thumbData];
                                       if (!path.length) {
                                           return;
                                       }
                                       model.thumbUrl = thumbName;
                                       model.thumbSize = info[RGImagePickerResourceThumbSize];
                                       
                                       filename = [asset.localIdentifier stringByAppendingPathComponent:filename];
                                       if (!isGif) {
                                           path = [CTFileManger.cacheManager createFile:filename atFolder:UCChatDataFolderName data:imageData];
                                           if (!path.length) {
                                               return;
                                           }
                                       }
                                       model.originalImageUrl = filename;
                                       model.originalImageSize = info[RGImagePickerResourceSize];
                                       [self insertChatData:model];
                                   }];
                               }];
                           }];
```

### Image Edit
under development

### Picker Sort
under development

