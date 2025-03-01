#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_media_metadata.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_media_metadata'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin to read metadata of media files.'
  s.description      = <<-DESC
A Flutter plugin to read metadata of media files.
                       DESC
  s.homepage         = 'https://github.com/alexmercerind/flutter_media_metadata'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hitesh Kumar Saini' => 'saini123hitesh@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
