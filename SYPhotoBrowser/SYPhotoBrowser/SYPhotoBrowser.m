//
//  SYPhotoBrowser.m
//  SYPhotoBrowser
//
//  Created by Sunnyyoung on 16/3/30.
//  Copyright © 2016年 Sunnyyoung. All rights reserved.
//

#import "SYPhotoBrowser.h"
#import "SYPhotoViewController.h"

static const CGFloat SYPhotoBrowserPageControlHeight = 40.0;

@interface SYPhotoBrowser () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, weak) id <SYPhotoBrowserDelegate> photoBrowserDelegate;

@property (nonatomic, strong) UIPageControl *systemPageControl;
@property (nonatomic, strong) UILabel *labelPageControl;
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
    [self setupPageControl];
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
    [self updatePageControlWithPageIndex:((SYPhotoViewController *)pendingViewControllers.lastObject).pageIndex];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    [((SYPhotoViewController *)previousViewControllers.lastObject) resetImageSize];
    if (!completed) {
        [self updatePageControlWithPageIndex:((SYPhotoViewController *)previousViewControllers.lastObject).pageIndex];
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

#pragma mark - Private method

- (void)setupPageControl {
    if (self.pageControlStyle == SYPhotoBrowserPageControlStyleSystem) {
        self.systemPageControl.numberOfPages = self.imageSourceArray.count;
        self.systemPageControl.currentPage = self.initialPageIndex;
    } else {
        self.labelPageControl.text = [NSString stringWithFormat:@"%@/%@", @(self.initialPageIndex+1), @(self.imageSourceArray.count)];
    }
}

- (void)updatePageControlWithPageIndex:(NSUInteger)pageIndex {
    if (self.pageControlStyle == SYPhotoBrowserPageControlStyleSystem) {
        self.systemPageControl.currentPage = pageIndex;
    } else {
        self.labelPageControl.text = [NSString stringWithFormat:@"%@/%@", @(pageIndex+1), @(self.imageSourceArray.count)];
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

- (UIPageControl *)systemPageControl {
    if (_systemPageControl == nil) {
        _systemPageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-SYPhotoBrowserPageControlHeight, CGRectGetWidth(self.view.bounds), SYPhotoBrowserPageControlHeight)];
        _systemPageControl.userInteractionEnabled = NO;
        _systemPageControl.hidesForSinglePage = YES;
        [self.view addSubview:_systemPageControl];
    }
    return _systemPageControl;
}

- (UILabel *)labelPageControl {
    if (_labelPageControl == nil) {
        _labelPageControl = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)-SYPhotoBrowserPageControlHeight, CGRectGetWidth(self.view.bounds), SYPhotoBrowserPageControlHeight)];
        _labelPageControl.textAlignment = NSTextAlignmentCenter;
        _labelPageControl.textColor = [UIColor whiteColor];
        _labelPageControl.font = [UIFont systemFontOfSize:14.0];
        [self.view addSubview:_labelPageControl];
    }
    return _labelPageControl;
}

@end
