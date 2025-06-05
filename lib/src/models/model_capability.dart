import 'dart:io';
import 'package:flutter/services.dart';
import '../ffi/native_edge_llm_bridge.dart';

/// Device capability assessment for determining on-device model feasibility
class ModelCapability {
  const ModelCapability._({
    required this.hasNeuralEngine,
    required this.availableMemoryGB,
    required this.deviceModel,
    required this.osVersion,
    required this.batteryLevel,
    required this.cpuCoreCount,
    required this.isLowPowerMode,
  });

  /// Evaluates the current device's capability for on-device inference
  static Future<ModelCapability> evaluate() async {
    try {
      final bridge = NativeEdgeLlmBridge();
      final capabilities = await bridge.getDeviceCapabilities();

      return ModelCapability._(
        hasNeuralEngine: capabilities['hasNeuralEngine'] as bool? ?? false,
        availableMemoryGB:
            (capabilities['availableMemoryGB'] as num?)?.toDouble() ?? 4.0,
        deviceModel: capabilities['deviceModel'] as String? ?? 'Unknown',
        osVersion: capabilities['osVersion'] as String? ?? 'Unknown',
        batteryLevel: (capabilities['batteryLevel'] as num?)?.toDouble() ?? 0.8,
        cpuCoreCount: capabilities['cpuCoreCount'] as int? ?? 4,
        isLowPowerMode: capabilities['isLowPowerMode'] as bool? ?? false,
      );
    } catch (e) {
      // Fallback to reasonable defaults if platform calls fail
      print(
          'Warning: Could not get real device capabilities, using fallback: $e');
      return ModelCapability._(
        hasNeuralEngine: Platform.isIOS && _isModernIOSDevice(),
        availableMemoryGB: _estimateMemoryBasedOnPlatform(),
        deviceModel: _getBasicDeviceModel(),
        osVersion: Platform.operatingSystemVersion,
        batteryLevel: 0.8,
        cpuCoreCount: Platform.numberOfProcessors,
        isLowPowerMode: false,
      );
    }
  }

  /// Whether the device has a Neural Engine (A11+ chips)
  final bool hasNeuralEngine;

  /// Available memory in GB for model loading
  final double availableMemoryGB;

  /// Device model identifier
  final String deviceModel;

  /// Operating system version
  final String osVersion;

  /// Current battery level (0.0-1.0)
  final double batteryLevel;

  /// Number of CPU cores
  final int cpuCoreCount;

  /// Whether low power mode is enabled
  final bool isLowPowerMode;

  /// Determines if the device can handle the specified model requirements
  bool canHandleModel({
    required double modelSizeGB,
    required double memoryOverheadGB,
    required double minBatteryLevel,
  }) {
    // Check memory requirements
    final totalMemoryRequired = modelSizeGB + memoryOverheadGB;
    if (totalMemoryRequired > availableMemoryGB) {
      return false;
    }

    // Check battery level
    if (batteryLevel < minBatteryLevel) {
      return false;
    }

    // Check if low power mode is enabled (reduces performance)
    if (isLowPowerMode) {
      return false;
    }

    return true;
  }

  /// Estimates performance tier based on device capabilities
  PerformanceTier get performanceTier {
    // Neural Engine devices
    if (hasNeuralEngine && availableMemoryGB >= 6) {
      if (_isA17OrNewer() || _isMSeries()) {
        return PerformanceTier.high;
      } else if (_isA15OrNewer()) {
        return PerformanceTier.medium;
      } else {
        return PerformanceTier.low;
      }
    }

    // CPU-only devices
    if (cpuCoreCount >= 6 && availableMemoryGB >= 4) {
      return PerformanceTier.cpuMedium;
    }

    return PerformanceTier.cpuLow;
  }

  /// Estimates expected first token latency in milliseconds
  int estimateFirstTokenLatencyMs() {
    switch (performanceTier) {
      case PerformanceTier.high:
        return 150; // A17 Pro / M-series target
      case PerformanceTier.medium:
        return 250; // A15-A16 with Neural Engine
      case PerformanceTier.low:
        return 400; // A11-A14 with Neural Engine
      case PerformanceTier.cpuMedium:
        return 800; // CPU-only, good specs
      case PerformanceTier.cpuLow:
        return 1500; // CPU-only, limited specs
    }
  }

  /// Estimates tokens per second throughput
  double estimateTokensPerSecond() {
    switch (performanceTier) {
      case PerformanceTier.high:
        return 25.0; // A17 Pro / M-series
      case PerformanceTier.medium:
        return 15.0; // A15-A16
      case PerformanceTier.low:
        return 8.0; // A11-A14
      case PerformanceTier.cpuMedium:
        return 5.0; // CPU-only, good specs
      case PerformanceTier.cpuLow:
        return 2.0; // CPU-only, limited specs
    }
  }

  bool _isA17OrNewer() {
    // Check for A17 Pro (iPhone 15 Pro) or newer
    return deviceModel.contains('iPhone15') ||
        deviceModel.contains('iPhone16') ||
        deviceModel.contains('iPhone17');
  }

  bool _isA15OrNewer() {
    // Check for A15 (iPhone 13) or newer
    return deviceModel.contains('iPhone13') ||
        deviceModel.contains('iPhone14') ||
        _isA17OrNewer();
  }

  bool _isMSeries() {
    // Check for M-series chips (Mac)
    return deviceModel.contains('Mac') ||
        deviceModel.toLowerCase().contains('apple') ||
        Platform.isMacOS;
  }

  // Fallback methods for when platform channels fail
  static bool _isModernIOSDevice() {
    // Basic heuristic - iOS devices from recent years likely have Neural Engine
    try {
      final version = Platform.operatingSystemVersion;
      final match = RegExp(r'(\d+)\.').firstMatch(version);
      if (match != null) {
        final majorVersion = int.tryParse(match.group(1) ?? '');
        return majorVersion != null && majorVersion >= 11;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return true; // Assume modern device
  }

  static double _estimateMemoryBasedOnPlatform() {
    if (Platform.isMacOS) {
      return 8.0; // Macs typically have more RAM
    } else if (Platform.isIOS) {
      return 6.0; // Modern iPhones typically have 6-8GB
    }
    return 4.0; // Conservative default
  }

  static String _getBasicDeviceModel() {
    if (Platform.isMacOS) {
      return 'Mac';
    } else if (Platform.isIOS) {
      return 'iPhone';
    }
    return Platform.operatingSystem;
  }

  @override
  String toString() {
    return 'ModelCapability('
        'tier: $performanceTier, '
        'neuralEngine: $hasNeuralEngine, '
        'memory: ${availableMemoryGB.toStringAsFixed(1)}GB, '
        'battery: ${(batteryLevel * 100).toStringAsFixed(0)}%, '
        'device: $deviceModel)';
  }
}

/// Performance tier classification for devices
enum PerformanceTier {
  /// A17 Pro / M-series chips with Neural Engine
  high,

  /// A15-A16 chips with Neural Engine
  medium,

  /// A11-A14 chips with Neural Engine
  low,

  /// CPU-only with good specs (6+ cores, 4+ GB RAM)
  cpuMedium,

  /// CPU-only with limited specs
  cpuLow,
}
