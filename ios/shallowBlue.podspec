#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint shallowBlue.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'shallowblue'
  s.version          = '0.0.1'
  s.summary          = 'ShallowBlue Chess Engine.'
  s.description      = <<-DESC
  ShallowBlue Chess Engine.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*', 'FlutterShallowBlue/*', 'ShallowBlue/src/*.cpp'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  # shallowBlue Compiler Settings
  s.library = 'c++'
  s.xcconfig = { 
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'OTHER_CPLUSPLUSFLAGS' => '$(inherited) -Wall -O3 -march=native -flto -pthread -fno-exceptions'
  }
end
