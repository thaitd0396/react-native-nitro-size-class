require "json"
package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name = "HabitifySizeClass"
  s.version = package["version"]
  s.summary = package["description"]
  s.homepage = package["homepage"]
  s.license = package["license"]
  s.author = package["author"]
  s.platform = :ios, '16.2'
  s.source = { :git => 'https://github.com/thaitd0396/react-native-nitro-size-class.git', :tag => "v#{s.version}" }
  s.source_files = 'ios/**/*.swift'
  s.swift_version = '5.0'
  load File.join(__dir__, 'nitrogen/generated/ios/HabitifySizeClass+autolinking.rb')
  add_nitrogen_files(s)
end
