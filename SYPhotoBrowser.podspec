Pod::Spec.new do |s|

  s.name         = "SYPhotoBrowser"
  s.version      = "2.1"
  s.summary      = "A cute and lightweight photo browser like Tweetbot3."
  s.homepage     = "https://github.com/Sunnyyoung/SYPhotoBrowser"
  s.license      = "MIT"
  s.authors      = { 'Sunnyyoung' => 'https://github.com/Sunnyyoung' }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/Sunnyyoung/SYPhotoBrowser.git", :tag => s.version }
  s.source_files = "SYPhotoBrowser/SYPhotoBrowser/*.{h,m}"
  s.requires_arc = true
  s.dependency 'SDWebImage'
  s.dependency 'DACircularProgress'

end