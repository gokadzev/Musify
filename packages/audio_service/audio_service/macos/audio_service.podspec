#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint audio_service.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'audio_service'
  s.version          = '0.14.1'
  s.summary          = 'Flutter plugin to play audio in the background while the screen is off.'
  s.description      = <<-DESC
Flutter plugin to play audio in the background while the screen is off.
                       DESC
  s.homepage         = 'https://github.com/ryanheise/audio_service'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ryan Heise' => 'ryan@ryanheise.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.12.2'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
