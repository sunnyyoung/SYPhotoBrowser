//
//  SYPhotoBrowser.h
//  SYPhotoBrowser
//
//  Created by Sunnyyoung on 16/3/30.
//  Copyright © 2016年 Sunnyyoung. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const SYPhotoBrowserDismissNotification   = @"SYPhotoBrowserDismissNotification";
static NSString * const SYPhotoBrowserLongPressNotification = @"SYPhotoBrowserLongPressNotification";

@class SYPhotoBrowser;

typedef NS_ENUM(NSUInteger, SYPhotoBrowserPageControlStyle) {
    SYPhotoBrowserPageControlStyleSystem = 0,
    SYPhotoBrowserPageControlStyleLabel
};

@protocol SYPhotoBrowserDelegate <NSObject>

@optional
- (void)photoBrowser:(SYPhotoBrowser *)photoBrowser didLongPressImage:(UIImage *)image;

@end

@interface SYPhotoBrowser : UIPageViewController

- (instancetype)initWithImageSource:(id)imageSource caption:(NSString *)caption;
- (instancetype)initWithImageSource:(id)imageSource caption:(NSString *)caption delegate:(id)delegate;
- (instancetype)initWithImageSourceArray:(NSArray *)imageSourceArray caption:(NSString *)caption;
- (instancetype)initWithImageSourceArray:(NSArray *)imageSourceArray caption:(NSString *)caption delegate:(id)delegate;

@property (nonatomic, assign) NSUInteger initialPageIndex;
@property (nonatomic, assign) SYPhotoBrowserPageControlStyle pageControlStyle;
@property (nonatomic, assign) BOOL enableStatusBarHidden;

@end
