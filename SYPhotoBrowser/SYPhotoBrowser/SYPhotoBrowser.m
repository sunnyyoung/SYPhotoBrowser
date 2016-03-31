//
//  SYPhotoBrowser.m
//  SYPhotoBrowser
//
//  Created by Sunnyyoung on 16/3/30.
//  Copyright © 2016年 Sunnyyoung. All rights reserved.
//

#import "SYPhotoBrowser.h"
#import "SYPhotoViewController.h"

@interface SYPhotoBrowser () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, weak) id <SYPhotoBrowserDelegate> photoBrowserDelegate;

@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSMutableArray *photoViewControllerArray;
@property (nonatomic, strong) NSArray *imageSourceArray;

@end

@implementation SYPhotoBrowser

#pragma mark - LifeCycle

- (instancetype)init {
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:@{UIPageViewControllerOptionInterPageSpacingKey: @(10)}];
    if (self) {
        self.dataSource = self;
        self.delegate = self;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDissmissNotification:) name:SYPhotoBrowserDismissNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLongPressNotification:) name:SYPhotoBrowserLongPressNotification object:nil];
    }
    return self;
}

- (instancetype)initWithImageSource:(id)imageSource {
    self = [self init];
    if (self) {
        self.imageSourceArray = @[imageSource];
    }
    return self;
}

- (instancetype)initWithImageSource:(id)imageSource delegate:(id)delegate {
    self = [self initWithImageSource:imageSource];
    if (self) {
        self.photoBrowserDelegate = delegate;
    }
    return self;
}

- (instancetype)initWithImageSourceArray:(NSArray *)imageSourceArray {
    self = [self init];
    if (self) {
        self.imageSourceArray = imageSourceArray.copy;
    }
    return self;
}

- (instancetype)initWithImageSourceArray:(NSArray *)imageSourceArray delegate:(id)delegate {
    self = [self initWithImageSourceArray:imageSourceArray];
    if (self) {
        self.photoBrowserDelegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    for (NSUInteger index = 0; index < self.imageSourceArray.count; index++) {
        id imageSource = self.imageSourceArray[index];
        SYPhotoViewController *photoViewController = [[SYPhotoViewController alloc] initWithImageSouce:imageSource pageIndex:index];
        [self.photoViewControllerArray addObject:photoViewController];
    }
    self.view.backgroundColor = [UIColor blackColor];
    self.pageControl.numberOfPages = self.imageSourceArray.count;
    self.pageControl.currentPage = self.initialPageIndex;
    [self setViewControllers:@[self.photoViewControllerArray[self.initialPageIndex]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (void)dealloc {
    self.dataSource = nil;
    self.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - PageView DataSouce

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = ((SYPhotoViewController *)viewController).pageIndex;
    if (index == 0) {
        return nil;
    } else {
        index--;
        SYPhotoViewController *photoViewController = self.photoViewControllerArray[index];
        return photoViewController;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = ((SYPhotoViewController *)viewController).pageIndex;
    if (index == self.photoViewControllerArray.count - 1) {
        return nil;
    } else {
        index++;
        SYPhotoViewController *photoViewController = self.photoViewControllerArray[index];
        return photoViewController;
    }
}

#pragma mark - PageView Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    self.pageControl.currentPage = ((SYPhotoViewController *)pendingViewControllers.lastObject).pageIndex;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    [((SYPhotoViewController *)previousViewControllers.lastObject) resetImageSize];
    if (!completed) {
        self.pageControl.currentPage = ((SYPhotoViewController *)previousViewControllers.lastObject).pageIndex;
    }
}

#pragma mark - Notification Handler

- (void)handleDissmissNotification:(NSNotification *)notification {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleLongPressNotification:(NSNotification *)notification {
    if ([self.photoBrowserDelegate respondsToSelector:@selector(photoBrowser:didLongPressImage:)]) {
        [self.photoBrowserDelegate photoBrowser:self didLongPressImage:notification.object];
    }
}

#pragma mark - Property method

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (NSMutableArray *)photoViewControllerArray {
    if (_photoViewControllerArray == nil) {
        _photoViewControllerArray = [NSMutableArray array];
    }
    return _photoViewControllerArray;
}

- (UIPageControl *)pageControl {
    if (_pageControl == nil) {
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-40.0, CGRectGetWidth(self.view.bounds), 40.0)];
        _pageControl.userInteractionEnabled = NO;
        _pageControl.hidesForSinglePage = YES;
        [self.view addSubview:_pageControl];
    }
    return _pageControl;
}

@end
