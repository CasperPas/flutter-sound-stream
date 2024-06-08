#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint sound_stream.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'sound_stream'
  s.version          = '0.1.0'
  s.summary          = 'A flutter plugin for streaming audio data from mic & to speaker'
  s.description      = <<-DESC
  A flutter plugin for streaming audio data from mic & to speaker
                       DESC
  s.homepage         = 'https://github.com/CasperPas/flutter-sound-stream'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Jeff Le' => 'me@jeffle.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
