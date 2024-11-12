#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'audiotagger'
  s.version          = '2.2.1'
  s.summary          = 'Library to read and write ID3 tags to MP3 files. You can get data as Map object or Tag object.'
  s.description      = <<-DESC
  Library to read and write ID3 tags to MP3 files. You can get data as Map object or Tag object.
                       DESC
  s.homepage         = 'https://rebaioli.altervista.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nicolò Rebaioli' => 'niko.reba@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '8.0'
end

