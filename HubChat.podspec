Pod::Spec.new do |s|
  s.name         = 'HubChat'
  s.version      = '1.0.0'
  s.summary      = 'HubChat support chat widget for iOS.'
  s.homepage     = 'https://github.com/HubChat-ai/hubchat-ios'
  s.license      = { :type => 'MIT' }
  s.author       = 'HubChat'
  s.source       = { :git => 'https://github.com/HubChat-ai/hubchat-ios.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.7'
  s.source_files = 'Sources/HubChat/**/*.swift'
end
