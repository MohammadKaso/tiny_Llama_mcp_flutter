Pod::Spec.new do |s|
  s.name             = 'edge_mcp_flutter'
  s.version          = '0.1.0'
  s.summary          = 'Real on-device LLM inference with MLC-LLM compiled TinyLlama model'
  s.description      = <<-DESC
EdgeMcp Flutter plugin providing real on-device Large Language Model inference using MLC-LLM 
compiled TinyLlama-1.1B-Chat model. Features Metal GPU acceleration, Neural Engine utilization, 
and privacy-preserving local processing with ~50ms per token performance.
                       DESC
  s.homepage         = 'https://github.com/username/edge_mcp_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Frameworks for MLC-LLM and Metal acceleration
  s.frameworks = 'Metal', 'MetalKit', 'Foundation', 'UIKit', 'Accelerate'
  
  # Swift language version
  s.swift_version = '5.0'

  # Include source files (including real MLCSwift implementation)
  s.source_files = 'Classes/**/*'
  
  # Public headers for Objective-C++ bridge
  s.public_header_files = 'Classes/EdgeMcpFlutter.h', 'Classes/MLCBridge.h'
  
  # Module map for proper Swift/ObjC++ integration
  s.module_map = 'Classes/module.modulemap'
  
  # TinyLlama model resources (716.24 MB compiled model) - direct resources
  s.resources = ['model/**/*']
  
  # MLC-LLM static libraries for real inference
  s.vendored_libraries = ['lib/libmlc_llm_static.a', 'lib/libtvm_runtime.a', 'lib/libtokenizers_c.a', 'lib/libtokenizers_cpp.a', 'lib/libsentencepiece.a']

  # Enhanced compiler configuration with TVM include paths for real MLC-LLM
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-lc++ -lz',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'GCC_C_LANGUAGE_STANDARD' => 'c11',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/../mlc-llm/3rdparty/tvm/include" "$(PODS_ROOT)/../mlc-llm/cpp" "$(PODS_ROOT)/../include"'
  }
end 