#
# Be sure to run `pod lib lint KKUnionPayHelper.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KKUnionPayHelper'
  s.version          = '3.3.12'
  s.summary          = 'KKUnionPayHelper is a Tool for China UnionPay.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
KKUnionPayHelper is a Tool for China UnionPay,Convenient and Fast Inheritance of Payment Function.
                       DESC

  s.homepage         = 'https://github.com/BradBin/KKUnionPayHelper'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'BradBin' => '820280738@qq.com' }
  s.source           = { :git => 'https://github.com/BradBin/KKUnionPayHelper.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.source_files        = 'KKUnionPayHelper/Classes/**/*.{h,m}'
  s.vendored_libraries  = 'KKUnionPayHelper/Classes/**/*.a'
  s.public_header_files = 'KKUnionPayHelper/Classes/**/KKUnionPay{Helper,Manager}.h'

  s.requires_arc     = true
  s.static_framework = true
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-all_load'}
  # s.resource_bundles = {
  #   'KKUnionPayHelper' => ['KKUnionPayHelper/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'CFNetwork','PassKit','SystemConfiguration'
  s.libraries = 'z','c++'
  # s.dependency 'AFNetworking', '~> 2.3'
end
