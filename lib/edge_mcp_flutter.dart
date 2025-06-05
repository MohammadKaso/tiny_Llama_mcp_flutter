/// EdgeMcp_flutter: On-device LLM inference for iOS/macOS with cloud fallback
///
/// This library provides seamless on-device LLM inference using Apple's Neural Engine
/// and Core ML, with automatic fallback to cloud models when device performance
/// doesn't meet the specified latency/memory targets.
library edge_mcp_flutter;

export 'src/edge_llm_ios.dart';
export 'src/models/policy.dart';
export 'src/models/cloud_config.dart';
export 'src/models/model_capability.dart';
export 'src/models/telemetry.dart';
export 'src/exceptions/edge_llm_exception.dart';
