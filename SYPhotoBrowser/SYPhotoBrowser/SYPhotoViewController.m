//
//  SYPhotoViewController.m
//  SYPhotoBrowser
//
//  Created by Sunnyyoung on 16/3/30.
//  Copyright © 2016年 Sunnyyoung. All rights reserved.
//

#import "SYPhotoViewController.h"
#import "SYPhotoBrowser.h"

@interface SYPhotoViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *loadedImage;
@property (nonatomic, strong) DACircularProgressView *progressView;
@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, strong) UIAttachmentBehavior *attachmentBehavior;

@end

@implementation SYPhotoViewController

#pragma mark - LifeCycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (instancetype)initWithImageSouce:(id)imageSouce pageIndex:(NSUInteger)pageIndex {
    self = [self init];
    if (self) {
        _imageSource = imageSouce;
        _pageIndex = pageIndex;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareImageToShow];
}

- (void)viewWillLayoutSubviews {
    //Scrollview
    [self.scrollView setFrame:self.view.bounds];
    
    //Set the aspect ration of the image
    float hfactor = self.loadedImage.size.width / CGRectGetWidth(self.view.bounds);
    float vfactor = self.loadedImage.size.height / CGRectGetHeight(self.view.bounds);
    float factor = fmax(hfactor, vfactor);
    
    //Divide the size by the greater of the vertical or horizontal shrinkage factor
    float newWidth = self.loadedImage.size.width / factor;
    float newHeight = self.loadedImage.size.height / factor;
    
    //Then figure out offset to center vertically or horizontally
    float leftOffset = (CGRectGetWidth(self.view.bounds) - newWidth) / 2;
    float topOffset = (CGRectGetHeight(self.view.bounds) - newHeight) / 2;
    
    //Reposition image view
    CGRect newRect = CGRectMake(leftOffset, topOffset, newWidth, newHeight);
    self.imageView.frame = newRect;
}

#pragma mark - ScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self.dynamicAnimator removeAllBehaviors];
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    self.imageView.frame = contentsFrame;
}

#pragma mark - GestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self.scrollView];
    return fabs(velocity.y) > fabs(velocity.x);
}

#pragma mark - Event Response

- (void)handleSingleTapGestureRecognizer:(UITapGestureRecognizer *)singleTapGestureRecognizer {
    [self dismiss];
}

- (void)handleDoubleTapGestureRecognizer:(UITapGestureRecognizer *)doubleTapGestureRecognizer {
    if (self.scrollView.zoomScale == self.scrollView.maximumZoomScale) {
        //Zoom out since we zoomed in here
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    } else {
        //Zoom to a point
        CGPoint touchPoint = [doubleTapGestureRecognizer locationInView:self.scrollView];
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
    }
}

- (void)handleLongPressGestureRecognizer:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SYPhotoBrowserLongPressNotification object:self.loadedImage];
    }
}

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self.dynamicAnimator removeAllBehaviors];
        
        CGPoint location = [panGestureRecognizer locationInView:self.scrollView];
        CGPoint imgLocation = [panGestureRecognizer locationInView:self.imageView];
        
        UIOffset centerOffset = UIOffsetMake(imgLocation.x - CGRectGetMidX(self.imageView.bounds),
                                             imgLocation.y - CGRectGetMidY(self.imageView.bounds));
        self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.imageView offsetFromCenter:centerOffset attachedToAnchor:location];
        [self.dynamicAnimator addBehavior:self.attachmentBehavior];
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        [self.attachmentBehavior setAnchorPoint:[panGestureRecognizer locationInView:self.scrollView]];
        self.parentViewController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [panGestureRecognizer locationInView:self.scrollView];
        CGRect closeTopThreshhold = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) * .25);
        CGRect closeBottomThreshhold = CGRectMake(0, CGRectGetHeight(self.view.bounds) - closeTopThreshhold.size.height, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) * .25);
        //Check if we should close - or just snap back to the center
        if (CGRectContainsPoint(closeTopThreshhold, location) || CGRectContainsPoint(closeBottomThreshhold, location)) {
            [self.dynamicAnimator removeAllBehaviors];
            self.imageView.userInteractionEnabled = NO;
            self.scrollView.userInteractionEnabled = NO;
            
            UIGravityBehavior *exitGravity = [[UIGravityBehavior alloc] initWithItems:@[self.imageView]];
            if (CGRectContainsPoint(closeTopThreshhold, location)) {
                exitGravity.gravityDirection = CGVectorMake(0.0, -1.0);
            }
            exitGravity.magnitude = 10.0f;
            [self.dynamicAnimator addBehavior:exitGravity];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismiss];
            });
        } else {
            self.parentViewController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];
            [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
            UISnapBehavior *snapBack = [[UISnapBehavior alloc] initWithItem:self.imageView snapToPoint:self.scrollView.center];
            [self.dynamicAnimator addBehavior:snapBack];
        }
    }
}

#pragma mark - Private method

- (UIImageView *)createImageView {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.loadedImage];
    imageView.frame = self.view.bounds;
    imageView.clipsToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.backgroundColor = [UIColor blackColor];
    
    //Scale to keep its aspect ration
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    float scaleFactor = (self.loadedImage ? self.loadedImage.size.width : screenWidth) / screenWidth;
    CGRect finalImageViewFrame = CGRectMake(0, (screenHeight/2)-((self.loadedImage.size.height / scaleFactor)/2), screenWidth, self.loadedImage.size.height / scaleFactor);
    imageView.layer.frame = finalImageViewFrame;
    
    //Toggle UI controls
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGestureRecognizer:)];
    singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [imageView setUserInteractionEnabled:YES];
    [imageView addGestureRecognizer:singleTapGestureRecognizer];
    
    //Recent the image on double tap
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGestureRecognizer:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [imageView addGestureRecognizer:doubleTapGestureRecognizer];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestureRecognizer:)];
    [imageView addGestureRecognizer:longPressGestureRecognizer];
    
    //Ensure the single tap doesn't fire when a user attempts to double tap
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    [singleTapGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
    
    //Dragging to dismiss
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
    panGestureRecognizer.delegate = self;
    [imageView addGestureRecognizer:panGestureRecognizer];
    return imageView;
}

- (void)prepareImageToShow {
    if ([self.imageSource isKindOfClass:[NSURL class]]) {
        //NSURL
        [self.view addSubview:self.progressView];
        NSURL *url = self.imageSource;
        [self downloadImageFromURL:url];
    } else if ([self.imageSource isKindOfClass:[NSString class]]) {
        //NSString->NSURL
        [self.view addSubview:self.progressView];
        NSURL *url = [NSURL URLWithString:self.imageSource];
        [self downloadImageFromURL:url];
    } else if ([self.imageSource isKindOfClass:[UIImage class]]) {
        //UIImage
        self.loadedImage = (UIImage *)self.imageSource;
        [self prepareImageViewToShow];
    }
}

- (void)prepareImageViewToShow {
    if (self.imageView) {
        return;
    }
    self.imageView = [self createImageView];
    [self.scrollView addSubview:self.imageView];
    // Sizes
    CGSize boundsSize = self.scrollView.bounds.size;
    CGSize imageSize = self.imageView.frame.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;
    CGFloat yScale = boundsSize.height / imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);
    
    // Calculate Max
    CGFloat maxScale = 6.0;
    if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        maxScale = maxScale / [[UIScreen mainScreen] scale];
        if (maxScale < minScale) {
            maxScale = minScale * 2;
        }
    }
    
    //Apply zoom
    self.scrollView.maximumZoomScale = maxScale;
    self.scrollView.minimumZoomScale = minScale;
    self.scrollView.zoomScale = minScale;
}

- (void)dismiss {
    [[NSNotificationCenter defaultCenter] postNotificationName:SYPhotoBrowserDismissNotification object:nil];
}

- (void)downloadImageFromURL:(NSURL *)url {
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:url options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        float fractionCompleted = (float)receivedSize/(float)expectedSize;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView setProgress:fractionCompleted];
        });
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self.progressView removeFromSuperview];
                NSLog(@"error %@", error);
            } else {
                self.loadedImage = image;
                [self prepareImageViewToShow];
                [self.progressView removeFromSuperview];
            }
        });
    }];
}

#pragma mark - Public method

- (void)resetImageSize {
    //重置图片的大小
    [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
}

#pragma mark - Property method

- (UIScrollView *)scrollView {
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _scrollView.delegate = self;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_scrollView];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        tapGestureRecognizer.cancelsTouchesInView = NO;
        [_scrollView addGestureRecognizer:tapGestureRecognizer];
    }
    return _scrollView;
}

- (DACircularProgressView *)progressView {
    if (_progressView == nil) {
        CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
        _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake((screenWidth-35.)/2., (screenHeight-35.)/2, 35.0f, 35.0f)];
        _progressView.progress = 0.0;
        _progressView.thicknessRatio = 0.1;
        _progressView.roundedCorners = NO;
        _progressView.trackTintColor = [UIColor colorWithWhite:0.2 alpha:1];
        _progressView.progressTintColor = [UIColor colorWithWhite:1.0 alpha:1];
    }
    return _progressView;
}

- (UIDynamicAnimator *)dynamicAnimator {
    if (_dynamicAnimator == nil) {
        _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.scrollView];
    }
    return _dynamicAnimator;
}

@end
