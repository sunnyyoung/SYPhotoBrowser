//
//  SYPhotoBrowserCaptionLabel.m
//  SYPhotoBrowser
//
//  Created by Sunnyyoung on 16/5/19.
//  Copyright © 2016年 Sunnyyoung. All rights reserved.
//

#import "SYPhotoBrowserCaptionLabel.h"

@interface SYPhotoBrowserCaptionLabel ()

@property (nonatomic, assign) UIEdgeInsets edgeInsets;

@end

@implementation SYPhotoBrowserCaptionLabel

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame edgeInsets:(UIEdgeInsets)edgeInsets {
    self = [super initWithFrame:frame];
    if (self) {
        self.edgeInsets = edgeInsets;
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.edgeInsets)];
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize value = [super sizeThatFits:size];
    value.width += self.edgeInsets.left + self.edgeInsets.right;
    value.height += self.edgeInsets.top + self.edgeInsets.bottom;
    return value;
}

@end
