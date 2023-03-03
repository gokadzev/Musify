#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint on_audio_query.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'on_audio_query_ios'
  s.version          = '1.0.0'
  s.summary          = 'Flutter Plugin that query medias from library'
  s.description      = <<-DESC
Flutter Plugin used to query audios/songs infos [title, artist, album, etc..] from device storage.
                       DESC
  s.homepage         = 'https://github.com/LucasPJS/on_audio_query'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Lucas Josino' => 'contact@lucasjosino.com' }
  s.source           = { :http => 'https://github.com/LucJosin/on_audio_query/tree/main/on_audio_query_ios' }
  s.documentation_url = 'https://pub.dev/packages/on_audio_query_ios'
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
