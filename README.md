#SYPhotoBrowser

A cute and lightweight photo browser like Tweetbot3.

##Screen Shot

![](https://raw.githubusercontent.com/Sunnyyoung/SYPhotoBrowser/master/ScreenShot/ScreenShot.gif)

##Requirments

1. iOS 7.0 and above.

##Dependency

- [SDWebImage](https://github.com/rs/SDWebImage)
- [DACircularProgress](https://github.com/danielamitay/DACircularProgress)

##Installation

To use `SYPhotoBrowser `

1. Edit your `Podfile`, add one line code `pod 'SYPhotoBrowser`
2. Run 'pod update'
3. `#import <SYPhotoBrowser/SYPhotoBrowser.h>`

##Quickstart

```objc
SYPhotoBrowser *photoBrowser = [[SYPhotoBrowser alloc] initWithImageSourceArray:self.urlArray caption:@"This is caption label" delegate:self];
photoBrowser.initialPageIndex = indexPath.row;
photoBrowser.pageControlStyle = SYPhotoBrowserPageControlStyleLabel;
[self presentViewController:photoBrowser animated:YES completion:nil];
```

##License
The [MIT License](LICENSE).
