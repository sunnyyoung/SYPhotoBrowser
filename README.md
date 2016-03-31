#SYPhotoBrowser

A simple and easy to use and lightweight photo browser, with nice performance.

##Screen Shot

![](https://raw.githubusercontent.com/Sunnyyoung/SYPhotoBrowser/master/ScreenShot/ScreenShot.gif)

##Requirments

1. iOS 7.0 and above.

##Installation

To use `SYPhotoBrowser `

1. Copy over the `SYPhotoBrowser` folder to your project.
2. `#import "SYPhotoBrowser.h"`

##Quickstart

```objc
SYPhotoBrowser *photoBrowser = [[SYPhotoBrowser alloc] initWithImageSourceArray:self.urlArray delegate:self];
[self presentViewController:imageVC animated:YES completion:nil];
```

##Credits

- [SDWebImage](https://github.com/rs/SDWebImage)
- [DACircularProgress](https://github.com/danielamitay/DACircularProgress)
- [buffer-ios-image-viewer](https://github.com/bufferapp/buffer-ios-image-viewer)

##License
The [MIT License](LICENSE).