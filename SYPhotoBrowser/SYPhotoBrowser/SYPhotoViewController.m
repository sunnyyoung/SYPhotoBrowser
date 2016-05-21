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

@property (nonatomic, assign) CGPoint beginTouchPoint;
@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, strong) UIDynamicItemBehavior *dynamicItemBehavior;
@property (nonatomic, strong) UIAttachmentBehavior *attachmentBehavior;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic, assign) BOOL enablePanGesture;

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
    [super viewWillLayoutSubviews];
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self resetImageSize];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.dynamicAnimator removeAllBehaviors];
}

#pragma mark - ScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (!scrollView.zooming) {
        self.enablePanGesture = scrollView.zoomScale <= 1.0;
    }
    // Reset ImageView Center
    CGSize contentSize = self.scrollView.contentSize;
    CGFloat offsetX = (CGRectGetWidth(self.scrollView.frame) > contentSize.width) ? (CGRectGetWidth(self.scrollView.frame) - contentSize.width) / 2.0 : 0.0;
    CGFloat offsetY = (CGRectGetHeight(self.scrollView.frame) > contentSize.height) ? (CGRectGetHeight(self.scrollView.frame) - contentSize.height) / 2.0 : 0.0;
    self.imageView.center = CGPointMake(self.scrollView.contentSize.width / 2.0 + offsetX, self.scrollView.contentSize.height / 2.0 + offsetY);
}

#pragma mark - GestureRecognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.scrollView.zoomScale != self.scrollView.minimumZoomScale) {
        return NO;
    } else {
        CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self.scrollView];
        return fabs(velocity.y) > fabs(velocity.x);
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    CGFloat transformScale = self.imageView.transform.a;
    BOOL shouldRecognize = transformScale > self.scrollView.minimumZoomScale;
    BOOL isTapGesture = [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]];
    // make sure tap and double tap gestures aren't recognized simultaneously
    return shouldRecognize && !isTapGesture;
}

#pragma mark - GestureRecognizer Handler

- (void)handleSingleTapGestureRecognizer:(UITapGestureRecognizer *)singleTapGestureRecognizer {
    [self dismiss];
}

- (void)handleDoubleTapGestureRecognizer:(UITapGestureRecognizer *)doubleTapGestureRecognizer {
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    } else {
        CGPoint tapPoint = [self.imageView convertPoint:[doubleTapGestureRecognizer locationInView:doubleTapGestureRecognizer.view] fromView:self.scrollView];
        CGFloat newZoomScale = self.scrollView.maximumZoomScale;
        CGFloat width = CGRectGetWidth(self.imageView.frame) / newZoomScale;
        CGFloat height = CGRectGetHeight(self.imageView.frame) / newZoomScale;
        if (width != CGRectGetWidth(self.imageView.frame)) {
            self.enablePanGesture = NO;
            CGRect zoomRect = CGRectMake(tapPoint.x - (width / 2.0), tapPoint.y - (height / 2.0), width, height);
            [self.scrollView zoomToRect:zoomRect animated:YES];
        }
    }
}

- (void)handleLongPressGestureRecognizer:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan && self.loadedImage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SYPhotoBrowserLongPressNotification object:self.loadedImage];
    }
}

- (void)handlePanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint touchLocation = [panGestureRecognizer locationInView:self.view];
    CGPoint imageLocation = [panGestureRecognizer locationInView:self.imageView];
    UIOffset centerOffset = UIOffsetMake(imageLocation.x - CGRectGetMidX(self.imageView.bounds), imageLocation.y - CGRectGetMidY(self.imageView.bounds));
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self.dynamicAnimator removeAllBehaviors];
        self.attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.imageView offsetFromCenter:centerOffset attachedToAnchor:touchLocation];
        [self.dynamicAnimator addBehavior:self.attachmentBehavior];
        [self.dynamicAnimator addBehavior:self.dynamicItemBehavior];
        CGRect imageFrame = self.imageView.frame;
        imageFrame.size.width *= self.scrollView.zoomScale;
        imageFrame.size.height *= self.scrollView.zoomScale;
        self.imageView.frame = imageFrame;
        self.beginTouchPoint = touchLocation;
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.attachmentBehavior.anchorPoint = touchLocation;
        CGFloat alpha = MAX(0.6, 1.0 - fabs(self.beginTouchPoint.y - touchLocation.y) / (CGRectGetHeight([UIScreen mainScreen].bounds)/2));
        self.parentViewController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:alpha];
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.dynamicAnimator removeBehavior:self.attachmentBehavior];
        // need to scale velocity values to tame down physics on the iPad
        CGFloat deviceVelocityScale = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 0.2 : 1.0;
        CGFloat deviceAngularScale = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 0.7 : 1.0;
        // factor to increase delay before `dismissAfterPush` is called on iPad to account for more area to cover to disappear
        CGFloat deviceDismissDelay = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 1.8 : 1.0;
        CGPoint velocity = [panGestureRecognizer velocityInView:self.view];
        CGFloat velocityAdjust = 10.0 * deviceVelocityScale;
        if (fabs(velocity.x / velocityAdjust) > 100.0 || fabs(velocity.y / velocityAdjust) > 100.0) {
            UIOffset offsetFromCenter = UIOffsetMake(imageLocation.x - CGRectGetMidX(self.imageView.bounds), imageLocation.y - CGRectGetMidY(self.imageView.bounds));
            CGFloat radius = sqrtf(powf(offsetFromCenter.horizontal, 2.0) + powf(offsetFromCenter.vertical, 2.0));
            CGFloat pushVelocity = sqrtf(powf(velocity.x, 2.0) + powf(velocity.y, 2.0));
            
            // calculate angles needed for angular velocity formula
            CGFloat velocityAngle = atan2f(velocity.y, velocity.x);
            CGFloat locationAngle = atan2f(offsetFromCenter.vertical, offsetFromCenter.horizontal);
            if (locationAngle > 0) {
                locationAngle -= M_PI * 2;
            }
            
            // angle (θ) is the angle between the push vector (V) and vector component parallel to radius, so it should always be positive
            CGFloat angle = fabs(fabs(velocityAngle) - fabs(locationAngle));
            // angular velocity formula: w = (abs(V) * sin(θ)) / abs(r)
            CGFloat angularVelocity = fabs((fabs(pushVelocity) * sinf(angle)) / fabs(radius));
            
            // rotation direction is dependent upon which corner was pushed relative to the center of the view
            // when velocity.y is positive, pushes to the right of center rotate clockwise, left is counterclockwise
            CGFloat direction = (touchLocation.x < panGestureRecognizer.view.center.x) ? -1.0 : 1.0;
            // when y component of velocity is negative, reverse direction
            if (velocity.y < 0) {
                direction *= -1;
            }
            
            // amount of angular velocity should be relative to how close to the edge of the view the force originated
            // angular velocity is reduced the closer to the center the force is applied
            // for angular velocity: positive = clockwise, negative = counterclockwise
            CGFloat xRatioFromCenter = fabs(offsetFromCenter.horizontal) / (CGRectGetWidth(self.imageView.frame) / 2.0);
            CGFloat yRatioFromCetner = fabs(offsetFromCenter.vertical) / (CGRectGetHeight(self.imageView.frame) / 2.0);
            
            // apply device scale to angular velocity
            angularVelocity *= deviceAngularScale;
            // adjust angular velocity based on distance from center, force applied farther towards the edges gets more spin
            angularVelocity *= ((xRatioFromCenter + yRatioFromCetner) / 2.0);
            
            UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.imageView] mode:UIPushBehaviorModeInstantaneous];
            pushBehavior.pushDirection = CGVectorMake((velocity.x / velocityAdjust), (velocity.y / velocityAdjust));
            pushBehavior.active = YES;
            [self.dynamicItemBehavior addAngularVelocity:angularVelocity * direction forItem:self.imageView];
            [self.dynamicAnimator addBehavior:pushBehavior];
            
            // delay for dismissing is based on push velocity also
            CGFloat delay = 0.5 - (pushVelocity / 10000.0);
            [self performSelector:@selector(dismiss) withObject:nil afterDelay:(delay * deviceDismissDelay)];
        } else {
            [self.dynamicAnimator removeAllBehaviors];
            [self resetImageSize];
            [UIView animateWithDuration:0.25 animations:^{
                self.parentViewController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];
            }];
        }
    }
}

#pragma mark - Private method

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

- (UIImageView *)createImageView {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.loadedImage];
    imageView.frame = self.view.bounds;
    imageView.clipsToBounds = YES;
    imageView.userInteractionEnabled = YES;
    imageView.layer.allowsEdgeAntialiasing = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor blackColor];
    
    //Scale to keep its aspect ration
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    float scaleFactor = (self.loadedImage ? self.loadedImage.size.width : screenWidth) / screenWidth;
    CGRect finalImageViewFrame = CGRectMake(0, (screenHeight/2.0)-((self.loadedImage.size.height / scaleFactor)/2.0), screenWidth, self.loadedImage.size.height / scaleFactor);
    imageView.layer.frame = finalImageViewFrame;
    
    //Toggle UI controls
    [imageView addGestureRecognizer:self.panGestureRecognizer];
    [imageView addGestureRecognizer:self.singleTapGestureRecognizer];
    [imageView addGestureRecognizer:self.doubleTapGestureRecognizer];
    [imageView addGestureRecognizer:self.longPressGestureRecognizer];
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
}

- (void)dismiss {
    [[NSNotificationCenter defaultCenter] postNotificationName:SYPhotoBrowserDismissNotification object:nil];
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
        _scrollView.maximumZoomScale = 6.0;
        [_scrollView addGestureRecognizer:self.singleTapGestureRecognizer];
        [self.view addSubview:_scrollView];
    }
    return _scrollView;
}

- (DACircularProgressView *)progressView {
    if (_progressView == nil) {
        CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
        _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake((screenWidth-35.0)/2.0, (screenHeight-35.0)/2.0, 35.0, 35.0)];
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
        _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    }
    return _dynamicAnimator;
}

- (UIDynamicItemBehavior *)dynamicItemBehavior {
    if (_dynamicItemBehavior == nil) {
        _dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.imageView]];
        _dynamicItemBehavior.friction = 0.2;
        _dynamicItemBehavior.density = 1.0;
        _dynamicItemBehavior.allowsRotation = YES;
    }
    return _dynamicItemBehavior;
}

- (UIPanGestureRecognizer *)panGestureRecognizer {
    if (_panGestureRecognizer == nil) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestureRecognizer:)];
        _panGestureRecognizer.delegate = self;
    }
    return _panGestureRecognizer;
}

- (UITapGestureRecognizer *)singleTapGestureRecognizer {
    if (_singleTapGestureRecognizer == nil) {
        _singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapGestureRecognizer:)];
        _singleTapGestureRecognizer.numberOfTapsRequired = 1;
        _singleTapGestureRecognizer.numberOfTouchesRequired = 1;
        [_singleTapGestureRecognizer requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];
        [_singleTapGestureRecognizer requireGestureRecognizerToFail:self.longPressGestureRecognizer];
    }
    return _singleTapGestureRecognizer;
}

- (UITapGestureRecognizer *)doubleTapGestureRecognizer {
    if (_doubleTapGestureRecognizer == nil) {
        _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapGestureRecognizer:)];
        _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        _doubleTapGestureRecognizer.numberOfTouchesRequired = 1;
    }
    return _doubleTapGestureRecognizer;
}

- (UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (_longPressGestureRecognizer == nil) {
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestureRecognizer:)];
    }
    return _longPressGestureRecognizer;
}

- (void)setEnablePanGesture:(BOOL)enablePanGesture {
    _enablePanGesture = enablePanGesture;
    if (enablePanGesture) {
        [self.imageView addGestureRecognizer:self.panGestureRecognizer];
    } else {
        [self.imageView removeGestureRecognizer:self.panGestureRecognizer];
    }
}

@end
