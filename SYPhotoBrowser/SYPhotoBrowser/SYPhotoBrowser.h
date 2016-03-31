//
//  SYPhotoBrowser.h
//  SYPhotoBrowser
//
//  Created by Sunnyyoung on 16/3/30.
//  Copyright © 2016年 Sunnyyoung. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const SYPhotoBrowserDismissNotification = @"SYPhotoBrowserDismissNotification";
static NSString * const SYPhotoBrowserLongPressNotification = @"SYPhotoBrowserLongPressNotification";

@class SYPhotoBrowser;

@protocol SYPhotoBrowserDelegate <NSObject>

@optional
- (void)photoBrowser:(SYPhotoBrowser *)photoBrowser didLongPressImage:(UIImage *)image;

@end

@interface SYPhotoBrowser : UIPageViewController

- (instancetype)initWithImageSource:(id)imageSource;
- (instancetype)initWithImageSource:(id)imageSource delegate:(id)delegate;
- (instancetype)initWithImageSourceArray:(NSArray *)imageSourceArray;
- (instancetype)initWithImageSourceArray:(NSArray *)imageSourceArray delegate:(id)delegate;

@property (nonatomic, assign) NSUInteger initialPageIndex;

@end
