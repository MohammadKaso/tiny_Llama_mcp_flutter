import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'models/policy.dart';
import 'models/cloud_config.dart';
import 'models/model_capability.dart';
import 'models/telemetry.dart';
import 'exceptions/edge_llm_exception.dart';
import 'ffi/native_edge_llm_bridge.dart';
import 'cloud/cloud_inference_engine.dart';

/// Main class for on-device LLM inference with cloud fallback
class EdgeLlmIOS {
  EdgeLlmIOS({
    required this.policy,
    this.cloud,
    this.onDeviceModelPath,
    this.enableTelemetry = true,
  }) : _telemetryAggregator = enableTelemetry ? TelemetryAggregator() : null,
       _nativeBridge = NativeEdgeLlmBridge(),
       _cloudEngine = cloud != null ? CloudInferenceEngine(cloud) : null;

  /// Policy for controlling device vs cloud selection
  final Policy policy;

  /// Cloud configuration for fallback
  final CloudConfig? cloud;

  /// Path to custom on-device model (.mlpackage or .mlc)
  final String? onDeviceModelPath;

  /// Whether to collect telemetry data
  final bool enableTelemetry;

  final TelemetryAggregator? _telemetryAggregator;
  final NativeEdgeLlmBridge _nativeBridge;
  final CloudInferenceEngine? _cloudEngine;

  ModelCapability? _cachedCapability;
  bool _isInitialized = false;

  /// Initialize the LLM engine and load models
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Evaluate device capabilities
      _cachedCapability = await ModelCapability.evaluate();

      // Initialize on-device model if policy allows
      if (policy.preferOnDevice && _cachedCapability!.hasNeuralEngine) {
        await _nativeBridge.initialize(
          modelPath: onDeviceModelPath ?? 'AppleIntelligence-3B',
        );
      }

      _isInitialized = true;
    } catch (e) {
      throw ModelLoadException('Failed to initialize EdgeLlmIOS: $e');
    }
  }

  /// Generate text with automatic device/cloud selection
  Stream<String> generate({
    required String prompt,
    String? system,
    int? maxTokens,
    double? temperature,
  }) async* {
    if (!_isInitialized) {
      await initialize();
    }

    final startTime = DateTime.now();

    try {
      // Decide inference strategy based on policy and device capability
      final strategy = await _selectInferenceStrategy();

      if (strategy == InferenceStrategy.device) {
        yield* _generateOnDevice(
          prompt: prompt,
          system: system,
          maxTokens: maxTokens,
          temperature: temperature,
          startTime: startTime,
        );
      } else {
        yield* _generateCloud(
          prompt: prompt,
          system: system,
          maxTokens: maxTokens,
          temperature: temperature,
          startTime: startTime,
        );
      }
    } catch (e) {
      // Record failure telemetry
      _recordTelemetry(
        source: InferenceSource.device,
        startTime: startTime,
        firstTokenTime: null,
        tokensGenerated: 0,
        errorMessage: e.toString(),
      );

      // Try cloud fallback if enabled and not already using cloud
      if (policy.allowCloudFallback && _cloudEngine != null) {
        try {
          yield* _generateCloud(
            prompt: prompt,
            system: system,
            maxTokens: maxTokens,
            temperature: temperature,
            startTime: DateTime.now(),
          );
        } catch (cloudError) {
          throw CloudFallbackException(
            'Both device and cloud inference failed',
            'Device: $e, Cloud: $cloudError',
          );
        }
      } else {
        rethrow;
      }
    }
  }

  /// Generate text using on-device model
  Stream<String> _generateOnDevice({
    required String prompt,
    String? system,
    int? maxTokens,
    double? temperature,
    required DateTime startTime,
  }) async* {
    DateTime? firstTokenTime;
    int tokensGenerated = 0;
    final buffer = StringBuffer();

    try {
      await for (final token in _nativeBridge.generate(
        prompt: prompt,
        system: system,
        maxTokens: maxTokens ?? 2048,
        temperature: temperature ?? 0.7,
      )) {
        // Record first token time
        if (firstTokenTime == null) {
          firstTokenTime = DateTime.now();
          final latency = firstTokenTime.difference(startTime).inMilliseconds;

          // Check if latency exceeds policy threshold
          if (latency > policy.maxFirstToken.inMilliseconds) {
            throw InsufficientCapabilityException(
              'First token latency ${latency}ms exceeds policy limit ${policy.maxFirstToken.inMilliseconds}ms',
            );
          }
        }

        tokensGenerated++;
        buffer.write(token);
        yield token;
      }

      // Record successful telemetry
      _recordTelemetry(
        source: InferenceSource.device,
        startTime: startTime,
        firstTokenTime: firstTokenTime,
        tokensGenerated: tokensGenerated,
      );
    } catch (e) {
      _recordTelemetry(
        source: InferenceSource.device,
        startTime: startTime,
        firstTokenTime: firstTokenTime,
        tokensGenerated: tokensGenerated,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Generate text using cloud model
  Stream<String> _generateCloud({
    required String prompt,
    String? system,
    int? maxTokens,
    double? temperature,
    required DateTime startTime,
  }) async* {
    if (_cloudEngine == null) {
      throw ConfigurationException('Cloud configuration not provided');
    }

    DateTime? firstTokenTime;
    int tokensGenerated = 0;

    try {
      await for (final token in _cloudEngine!.generate(
        prompt: prompt,
        system: system,
        maxTokens: maxTokens,
        temperature: temperature,
      )) {
        if (firstTokenTime == null) {
          firstTokenTime = DateTime.now();
        }

        tokensGenerated++;
        yield token;
      }

      // Record successful cloud telemetry
      _recordTelemetry(
        source: InferenceSource.cloud,
        startTime: startTime,
        firstTokenTime: firstTokenTime,
        tokensGenerated: tokensGenerated,
      );
    } catch (e) {
      _recordTelemetry(
        source: InferenceSource.cloud,
        startTime: startTime,
        firstTokenTime: firstTokenTime,
        tokensGenerated: tokensGenerated,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Select the best inference strategy based on policy and device capability
  Future<InferenceStrategy> _selectInferenceStrategy() async {
    final capability = _cachedCapability ?? await ModelCapability.evaluate();

    // Force cloud if policy dictates
    if (!policy.preferOnDevice) {
      return InferenceStrategy.cloud;
    }

    // Check if cloud is required due to missing configuration
    if (_cloudEngine == null && !capability.hasNeuralEngine) {
      throw ConfigurationException(
        'Device does not support on-device inference and no cloud configuration provided',
      );
    }

    // Check device capability constraints
    if (!capability.canHandleModel(
      modelSizeGB: 3.0, // Default Apple Intelligence model size
      memoryOverheadGB: 1.0,
      minBatteryLevel: policy.batteryThreshold,
    )) {
      if (policy.allowCloudFallback && _cloudEngine != null) {
        return InferenceStrategy.cloud;
      } else {
        throw InsufficientCapabilityException(
          'Device cannot handle model requirements and cloud fallback not available',
        );
      }
    }

    // Check estimated performance against policy
    final estimatedLatency = capability.estimateFirstTokenLatencyMs();
    if (estimatedLatency > policy.maxFirstToken.inMilliseconds) {
      if (policy.allowCloudFallback && _cloudEngine != null) {
        return InferenceStrategy.cloud;
      }
    }

    final estimatedTps = capability.estimateTokensPerSecond();
    if (estimatedTps < policy.minTokensPerSecond) {
      if (policy.allowCloudFallback && _cloudEngine != null) {
        return InferenceStrategy.cloud;
      }
    }

    return InferenceStrategy.device;
  }

  /// Record telemetry data for performance monitoring
  void _recordTelemetry({
    required InferenceSource source,
    required DateTime startTime,
    DateTime? firstTokenTime,
    required int tokensGenerated,
    String? errorMessage,
  }) {
    if (_telemetryAggregator == null) return;

    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);
    final firstTokenLatency =
        firstTokenTime?.difference(startTime) ?? totalDuration;

    final tokensPerSecond =
        tokensGenerated > 0 && totalDuration.inMilliseconds > 0
        ? (tokensGenerated * 1000) / totalDuration.inMilliseconds
        : 0.0;

    final telemetry = Telemetry(
      timestamp: endTime,
      source: source,
      firstTokenLatencyMs: firstTokenLatency.inMilliseconds,
      tokensPerSecond: tokensPerSecond,
      memoryUsageBytes: _estimateMemoryUsage(),
      batteryDrainPercent: 0.1, // Placeholder - would get from platform
      cpuUsagePercent: 50.0, // Placeholder - would get from platform
      fps: 60.0, // Placeholder - would get from UI performance monitor
      errorMessage: errorMessage,
    );

    _telemetryAggregator!.addSample(telemetry);
  }

  /// Estimate current memory usage
  int _estimateMemoryUsage() {
    // In a real implementation, this would query the native layer
    // For now, return a reasonable estimate
    return 3 * 1024 * 1024 * 1024; // 3GB for 3B model
  }

  /// Get telemetry statistics
  TelemetryStats? getStats([Duration? duration]) {
    return _telemetryAggregator?.getStats(duration);
  }

  /// Get device capability information
  ModelCapability? get deviceCapability => _cachedCapability;

  /// Check if the engine is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  Future<void> dispose() async {
    await _nativeBridge.dispose();
    _telemetryAggregator?.clear();
    _isInitialized = false;
  }
}

/// Strategy for inference execution
enum InferenceStrategy { device, cloud }
