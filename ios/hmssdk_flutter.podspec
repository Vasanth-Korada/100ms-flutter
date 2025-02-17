
Pod::Spec.new do |s|
  s.name             = 'hmssdk_flutter'
  s.version          = '0.5.0'
  s.summary          = 'The Flutter plugin for 100ms SDK'
  s.description      = <<-DESC
  A Flutter Project for 100ms SDK.
                       DESC
  s.homepage         = 'http://100ms.live'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Yogesh Singh' => 'yogesh@100ms.live' }
  s.source           = { :git => 'https://github.com/100mslive/100ms-flutter.git' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'HMSSDK'
  s.platform = :ios, '10.0'
  s.ios.deployment_target  = '10.0'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
