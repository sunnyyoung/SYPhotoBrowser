//
//  SYPhotoBrowser.m
//  SYPhotoBrowser
//
//  Created by Sunnyyoung on 16/3/30.
//  Copyright © 2016年 Sunnyyoung. All rights reserved.
//

#import "SYPhotoBrowser.h"
#import "SYPhotoBrowserCaptionLabel.h"
#import "SYPhotoViewController.h"

static const CGFloat SYPhotoBrowserPageControlHeight = 40.0;
static const CGFloat SYPhotoBrowserCaptionLabelPadding = 20.0;

@interface SYPhotoBrowser () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, weak) id <SYPhotoBrowserDelegate> photoBrowserDelegate;

// UI Property
@property (nonatomic, strong) UIPageControl *systemPageControl;
@property (nonatomic, strong) UILabel *labelPageControl;
@property (nonatomic, strong) SYPhotoBrowserCaptionLabel *captionLabel;

// Data Property
@property (nonatomic, strong) NSMutableArray *photoViewControllerArray;
@property (nonatomic, copy) NSArray *imageSourceArray;
@property (nonatomic, copy) NSString *caption;

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
        self.modalPresentationCapturesStatusBarAppearance = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDissmissNotification:) name:SYPhotoBrowserDismissNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLongPressNotification:) name:SYPhotoBrowserLongPressNotification object:nil];
    }
    return self;
}

- (instancetype)initWithImageSourceArray:(NSArray *)imageSourceArray caption:(NSString *)caption {
    self = [self init];
    if (self) {
        self.imageSourceArray = imageSourceArray;
        self.caption = caption;
    }
    return self;
}

- (instancetype)initWithImageSourceArray:(NSArray *)imageSourceArray caption:(NSString *)caption delegate:(id)delegate {
    self = [self init];
    if (self) {
        self.imageSourceArray = imageSourceArray;
        self.caption = caption;
        self.photoBrowserDelegate = delegate;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadPhotoViewControllers];
    [self updatePageControlWithPageIndex:self.initialPageIndex];
    [self updateCationLabelWithCaption:self.caption];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].keyWindow.windowLevel = UIWindowLevelAlert;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].keyWindow.windowLevel = UIWindowLevelNormal;
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
    if (completed) {
        [((SYPhotoViewController *)previousViewControllers.lastObject) resetImageSize];
    } else {
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

- (void)loadPhotoViewControllers {
    for (NSUInteger index = 0; index < self.imageSourceArray.count; index++) {
        id imageSource = self.imageSourceArray[index];
        SYPhotoViewController *photoViewController = [[SYPhotoViewController alloc] initWithImageSouce:imageSource pageIndex:index];
        [self.photoViewControllerArray addObject:photoViewController];
    }
    [self setViewControllers:@[self.photoViewControllerArray[self.initialPageIndex]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (void)updateCationLabelWithCaption:(NSString *)caption {
    if (caption.length) {
        self.captionLabel.text = caption;
        CGRect captionLabelFrame = self.captionLabel.frame;
        CGSize captionLabelSize = [self.captionLabel sizeThatFits:CGSizeMake(CGRectGetWidth(self.view.bounds) - SYPhotoBrowserCaptionLabelPadding*2, CGFLOAT_MAX)];
        captionLabelFrame.size.height = captionLabelSize.height;
        captionLabelFrame.origin.y -= CGRectGetHeight(captionLabelFrame);
        self.captionLabel.frame = captionLabelFrame;
        if (self.pageControlStyle == SYPhotoBrowserPageControlStyleSystem) {
            CGRect pageControlFrame = self.systemPageControl.frame;
            pageControlFrame.origin.y -= CGRectGetHeight(captionLabelFrame);
            self.systemPageControl.frame = pageControlFrame;
        } else {
            CGRect pageControlFrame = self.labelPageControl.frame;
            pageControlFrame.origin.y -= CGRectGetHeight(captionLabelFrame);
            self.labelPageControl.frame = pageControlFrame;
        }
    }
}

- (void)updatePageControlWithPageIndex:(NSUInteger)pageIndex {
    if (self.pageControlStyle == SYPhotoBrowserPageControlStyleSystem) {
        self.systemPageControl.numberOfPages = self.imageSourceArray.count;
        self.systemPageControl.currentPage = pageIndex;
    } else {
        self.labelPageControl.text = [NSString stringWithFormat:@"%@/%@", @(pageIndex+1), @(self.imageSourceArray.count)];
    }
}

#pragma mark - Property method

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
        _systemPageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0.0, CGRectGetHeight(self.view.bounds)-SYPhotoBrowserPageControlHeight, CGRectGetWidth(self.view.bounds), SYPhotoBrowserPageControlHeight)];
        _systemPageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        _systemPageControl.userInteractionEnabled = NO;
        _systemPageControl.hidesForSinglePage = YES;
        [self.view addSubview:_systemPageControl];
    }
    return _systemPageControl;
}

- (UILabel *)labelPageControl {
    if (_labelPageControl == nil) {
        _labelPageControl = [[UILabel alloc] initWithFrame:CGRectMake(0.0, CGRectGetHeight(self.view.bounds)-SYPhotoBrowserPageControlHeight, CGRectGetWidth(self.view.bounds), SYPhotoBrowserPageControlHeight)];
        _labelPageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        _labelPageControl.textAlignment = NSTextAlignmentCenter;
        _labelPageControl.textColor = [UIColor whiteColor];
        _labelPageControl.font = [UIFont systemFontOfSize:14.0];
        [self.view addSubview:_labelPageControl];
    }
    return _labelPageControl;
}

- (SYPhotoBrowserCaptionLabel *)captionLabel {
    if (_captionLabel == nil) {
        CGRect frame = CGRectMake(0.0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds), 0.0);
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(SYPhotoBrowserCaptionLabelPadding, SYPhotoBrowserCaptionLabelPadding, SYPhotoBrowserCaptionLabelPadding, SYPhotoBrowserCaptionLabelPadding);
        _captionLabel = [[SYPhotoBrowserCaptionLabel alloc] initWithFrame:frame edgeInsets:edgeInsets];
        _captionLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        _captionLabel.numberOfLines = 0;
        _captionLabel.textColor = [UIColor whiteColor];
        _captionLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
        _captionLabel.font = [UIFont systemFontOfSize:18.0];
        [self.view addSubview:_captionLabel];
    }
    return _captionLabel;
}

@end
