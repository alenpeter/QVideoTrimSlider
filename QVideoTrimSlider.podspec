#
#  Be sure to run `pod spec lint QVideoTrimSlider.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "QVideoTrimSlider"
  spec.version      = "0.0.4"
  spec.summary      = "Trim Videos"
  spec.description  = "A slider based video trimmer"


  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author    = "Alen Peter"
  spec.platform     = :ios
  
  spec.homepage		= "https://github.com/alenpeter/QVideoTrimSlider.git"
  spec.source       = { :git => "https://github.com/alenpeter/QVideoTrimSlider.git", :tag => "#{spec.version}" }


  spec.source_files  = "Classes", "QVideoTrimSlider/*.{swift}"
  spec.swift_version = "5.0"
  spec.ios.deployment_target = "10.1"


  spec.resources  = "QVideoTrimSlider/Assets.xcassets"

end
