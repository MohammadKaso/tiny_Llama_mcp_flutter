Pod::Spec.new do |s|
  s.name             = 'edge_mcp'
  s.version          = '0.0.1'
  s.summary          = 'Real on-device LLM inference with MLC-LLM compiled TinyLlama model'
  s.description      = <<-DESC
EdgeMcp Flutter plugin providing real on-device Large Language Model inference using MLC-LLM 
compiled TinyLlama-1.1B-Chat model. Features Metal GPU acceleration, Neural Engine utilization, 
and privacy-preserving local processing with ~50ms per token performance.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Metal framework for GPU acceleration
  s.frameworks = 'Metal', 'MetalKit', 'Foundation', 'UIKit'
  
  # MLC-LLM static libraries
  s.vendored_libraries = 'lib/libmlc_llm_static.a', 'lib/libtvm_runtime.a', 'lib/libtokenizers_cpp.a'
  
  # Compiler flags for MLC-LLM integration
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load $(PODS_TARGET_SRCROOT)/lib/libmlc_llm_static.a -force_load $(PODS_TARGET_SRCROOT)/lib/libtvm_runtime.a -force_load $(PODS_TARGET_SRCROOT)/lib/libtokenizers_cpp.a',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'GCC_C_LANGUAGE_STANDARD' => 'c11',
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/Classes',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  
  # Include TinyLlama model files as resources
  s.resource_bundles = {
    'TinyLlama' => ['model/**/*']
  }
  
  # Swift version
  s.swift_version = '5.0'
end 