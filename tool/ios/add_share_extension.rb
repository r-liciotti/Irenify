# Aggiunge al progetto Xcode il target "Share Extension" (F5 fase 2, D-69) al
# posto dei passi a mano di F0_CHECKLIST.md §2. Ripetibile: se il target c'è
# già non fa nulla. Uso (dalla radice del repo):
#   ruby tool/ios/add_share_extension.rb && (cd ios && LANG=en_US.UTF-8 pod install)
require 'xcodeproj'

PROJECT = File.expand_path('../../ios/Runner.xcodeproj', __dir__)
NAME = 'Share Extension'
GROUP_ID = 'group.it.overside.irenefy'
BUNDLE_ID = 'it.overside.irenefy.ShareExtension'

project = Xcodeproj::Project.open(PROJECT)
if project.targets.any? { |t| t.name == NAME }
  puts "#{NAME}: già presente, niente da fare"
  exit 0
end
runner = project.targets.find { |t| t.name == 'Runner' }
team = runner.build_configurations.first.build_settings['DEVELOPMENT_TEAM']

ext = project.new_target(:app_extension, NAME, :ios, '16.0', nil, :swift)

group = project.main_group.new_group(NAME, NAME)
source = group.new_reference('ShareViewController.swift')
ext.add_file_references([source])
group.new_reference('Info.plist')
group.new_reference("#{NAME}.entitlements")
xcconfigs = %w[Debug Release Profile].to_h { |c| [c, group.new_reference("#{c}.xcconfig")] }

ext.build_configurations.each do |config|
  config.base_configuration_reference = xcconfigs.fetch(config.name, xcconfigs['Release'])
  s = config.build_settings
  s['INFOPLIST_FILE'] = "#{NAME}/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['CODE_SIGN_ENTITLEMENTS'] = "#{NAME}/#{NAME}.entitlements"
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = team if team
  s['CUSTOM_GROUP_ID'] = GROUP_ID
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks',
                                  '@executable_path/../../Frameworks']
end

# Il Runner condivide l'App Group con l'extension.
runner.build_configurations.each do |config|
  config.build_settings['CUSTOM_GROUP_ID'] = GROUP_ID
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end
project.main_group['Runner'].new_reference('Runner.entitlements')

# L'extension si compila prima del Runner e finisce in PlugIns; la fase va
# prima di "Thin Binary" (README di receive_sharing_intent, punto 7).
runner.add_dependency(ext)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed.add_file_reference(ext.product_reference).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
runner.build_phases.delete(embed)
thin = runner.build_phases.index { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
runner.build_phases.insert(thin || runner.build_phases.length, embed)

project.save
puts "#{NAME}: aggiunto (#{BUNDLE_ID}, App Group #{GROUP_ID})"
