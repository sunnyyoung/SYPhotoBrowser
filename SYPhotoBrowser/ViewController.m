//
//  ViewController.m
//  SYPhotoBrowser
//
//  Created by Sunnyyoung on 16/3/30.
//  Copyright © 2016年 Sunnyyoung. All rights reserved.
//

#import "ViewController.h"
#import "CollectionViewCell.h"
#import "SYPhotoBrowser/SYPhotoBrowser.h"

@interface ViewController () <SYPhotoBrowserDelegate>

@property (nonatomic, strong) NSArray *urlArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.urlArray = @[@"http://iphone.tgbus.com/UploadFiles/201410/20141020134730646.jpg",
                      @"http://a.hiphotos.baidu.com/zhidao/pic/item/2cf5e0fe9925bc314cc6bd685fdf8db1ca1370a2.jpg",
                      @"http://d.3987.com/cgqfj_130528/001.jpg",
                      @"http://news.mydrivers.com/img/20130518/68d97fe443034db3bc3aef4d98ac9188.jpg"];
}

#pragma mark - CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.urlArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:self.urlArray[indexPath.row]]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    SYPhotoBrowser *photoBrowser = [[SYPhotoBrowser alloc] initWithImageSourceArray:self.urlArray delegate:self];
    photoBrowser.initialPageIndex = indexPath.row;
    photoBrowser.pageControlStyle = SYPhotoBrowserPageControlStyleLabel;
    photoBrowser.statusBarHidden = NO;
    [self presentViewController:photoBrowser animated:YES completion:nil];
}

#pragma mark - SYPhotoBrowser Delegate

- (void)photoBrowser:(SYPhotoBrowser *)photoBrowser didLongPressImage:(UIImage *)image {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"LongPress" message:@"Do somethings" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
