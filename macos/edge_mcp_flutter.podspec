Pod::Spec.new do |s|
  s.name             = 'edge_mcp_flutter'
  s.version          = '0.1.0'
  s.summary          = 'On-device LLM inference for iOS/macOS with cloud fallback using Apple\'s Neural Engine and Core ML.'
  s.description      = <<-DESC
EdgeMcp_flutter provides seamless on-device LLM inference using Apple's Neural Engine
and Core ML, with automatic fallback to cloud models when device performance
doesn't meet the specified latency/memory targets. Optimized for M-series chips.
                       DESC
  s.homepage         = 'https://github.com/username/edge_mcp_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'

  # CoreML and related frameworks for macOS
  s.frameworks = 'CoreML', 'Foundation', 'Cocoa'
  
  # macOS 14+ optimizations
  s.weak_frameworks = 'MLCompute'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end 