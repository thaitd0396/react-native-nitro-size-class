require 'xcodeproj'
root = File.dirname(__FILE__)
project = Xcodeproj::Project.new(File.join(root, 'SizeClassTests.xcodeproj'))
app = project.new_target(:application, 'SizeClassHarness', :ios, '17.0')
app.add_file_references(%w[App.swift Observer.swift Stubs.swift].map { |name| project.main_group.new_file(name) })
tests = project.new_target(:unit_test_bundle, 'SizeClassObserverTests', :ios, '17.0')
tests.add_file_references([project.main_group.new_file('Tests.swift')])
tests.add_dependency(app)
[app, tests].each do |target|
  target.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "co.unstatic.sizeclasstests.#{target.name}"
  end
end
app.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
end
tests.build_configurations.each do |config|
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/SizeClassHarness.app/SizeClassHarness'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(tests)
scheme.set_launch_target(app)
scheme.save_as(project.path, 'SizeClassHarness', true)
