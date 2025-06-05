/// Telemetry data for monitoring performance and resource usage
class Telemetry {
  const Telemetry({
    required this.timestamp,
    required this.source,
    required this.firstTokenLatencyMs,
    required this.tokensPerSecond,
    required this.memoryUsageBytes,
    required this.batteryDrainPercent,
    required this.cpuUsagePercent,
    required this.fps,
    this.errorMessage,
  });

  /// When this telemetry data was recorded
  final DateTime timestamp;

  /// Source of inference (device, cloud, hybrid)
  final InferenceSource source;

  /// Time to generate first token in milliseconds
  final int firstTokenLatencyMs;

  /// Tokens generated per second
  final double tokensPerSecond;

  /// Memory usage in bytes
  final int memoryUsageBytes;

  /// Battery drain percentage during inference
  final double batteryDrainPercent;

  /// CPU usage percentage during inference
  final double cpuUsagePercent;

  /// Frames per second (for UI performance monitoring)
  final double fps;

  /// Error message if inference failed
  final String? errorMessage;

  /// Memory usage in MB for display
  double get memoryUsageMB => memoryUsageBytes / (1024 * 1024);

  /// Memory usage in GB for display
  double get memoryUsageGB => memoryUsageBytes / (1024 * 1024 * 1024);

  /// Whether this represents a successful inference
  bool get isSuccess => errorMessage == null;

  /// Whether performance meets acceptable thresholds
  bool get meetsPerformanceTargets =>
      firstTokenLatencyMs <= 300 && tokensPerSecond >= 10.0 && fps >= 30.0;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'source': source.name,
    'firstTokenLatencyMs': firstTokenLatencyMs,
    'tokensPerSecond': tokensPerSecond,
    'memoryUsageBytes': memoryUsageBytes,
    'batteryDrainPercent': batteryDrainPercent,
    'cpuUsagePercent': cpuUsagePercent,
    'fps': fps,
    'errorMessage': errorMessage,
  };

  factory Telemetry.fromJson(Map<String, dynamic> json) => Telemetry(
    timestamp: DateTime.parse(json['timestamp'] as String),
    source: InferenceSource.values.byName(json['source'] as String),
    firstTokenLatencyMs: json['firstTokenLatencyMs'] as int,
    tokensPerSecond: (json['tokensPerSecond'] as num).toDouble(),
    memoryUsageBytes: json['memoryUsageBytes'] as int,
    batteryDrainPercent: (json['batteryDrainPercent'] as num).toDouble(),
    cpuUsagePercent: (json['cpuUsagePercent'] as num).toDouble(),
    fps: (json['fps'] as num).toDouble(),
    errorMessage: json['errorMessage'] as String?,
  );

  @override
  String toString() {
    return 'Telemetry('
        'source: $source, '
        'latency: ${firstTokenLatencyMs}ms, '
        'tps: ${tokensPerSecond.toStringAsFixed(1)}, '
        'memory: ${memoryUsageMB.toStringAsFixed(1)}MB, '
        'fps: ${fps.toStringAsFixed(1)}, '
        'success: $isSuccess)';
  }
}

/// Real-time telemetry aggregator for performance monitoring
class TelemetryAggregator {
  TelemetryAggregator() : _samples = [];

  final List<Telemetry> _samples;
  static const int _maxSamples = 100;

  /// Add a new telemetry sample
  void addSample(Telemetry sample) {
    _samples.add(sample);
    if (_samples.length > _maxSamples) {
      _samples.removeAt(0);
    }
  }

  /// Get all stored samples
  List<Telemetry> get samples => List.unmodifiable(_samples);

  /// Get samples from a specific time range
  List<Telemetry> getSamplesInRange(DateTime start, DateTime end) {
    return _samples
        .where(
          (sample) =>
              sample.timestamp.isAfter(start) && sample.timestamp.isBefore(end),
        )
        .toList();
  }

  /// Calculate average metrics over the specified duration
  TelemetryStats getStats([Duration? duration]) {
    final cutoff = duration != null
        ? DateTime.now().subtract(duration)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final relevantSamples = _samples
        .where((s) => s.timestamp.isAfter(cutoff))
        .toList();

    if (relevantSamples.isEmpty) {
      return const TelemetryStats.empty();
    }

    final successful = relevantSamples.where((s) => s.isSuccess).toList();
    final deviceSamples = relevantSamples
        .where((s) => s.source == InferenceSource.device)
        .toList();
    final cloudSamples = relevantSamples
        .where((s) => s.source == InferenceSource.cloud)
        .toList();

    return TelemetryStats(
      totalSamples: relevantSamples.length,
      successfulSamples: successful.length,
      deviceSamples: deviceSamples.length,
      cloudSamples: cloudSamples.length,
      avgFirstTokenLatencyMs: _average(
        successful.map((s) => s.firstTokenLatencyMs.toDouble()),
      ),
      avgTokensPerSecond: _average(successful.map((s) => s.tokensPerSecond)),
      avgMemoryUsageMB: _average(successful.map((s) => s.memoryUsageMB)),
      avgFps: _average(successful.map((s) => s.fps)),
      avgCpuUsage: _average(successful.map((s) => s.cpuUsagePercent)),
      avgBatteryDrain: _average(successful.map((s) => s.batteryDrainPercent)),
    );
  }

  double _average(Iterable<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Clear all stored samples
  void clear() => _samples.clear();
}

/// Aggregated telemetry statistics
class TelemetryStats {
  const TelemetryStats({
    required this.totalSamples,
    required this.successfulSamples,
    required this.deviceSamples,
    required this.cloudSamples,
    required this.avgFirstTokenLatencyMs,
    required this.avgTokensPerSecond,
    required this.avgMemoryUsageMB,
    required this.avgFps,
    required this.avgCpuUsage,
    required this.avgBatteryDrain,
  });

  const TelemetryStats.empty()
    : this(
        totalSamples: 0,
        successfulSamples: 0,
        deviceSamples: 0,
        cloudSamples: 0,
        avgFirstTokenLatencyMs: 0.0,
        avgTokensPerSecond: 0.0,
        avgMemoryUsageMB: 0.0,
        avgFps: 0.0,
        avgCpuUsage: 0.0,
        avgBatteryDrain: 0.0,
      );

  final int totalSamples;
  final int successfulSamples;
  final int deviceSamples;
  final int cloudSamples;
  final double avgFirstTokenLatencyMs;
  final double avgTokensPerSecond;
  final double avgMemoryUsageMB;
  final double avgFps;
  final double avgCpuUsage;
  final double avgBatteryDrain;

  /// Success rate as a percentage
  double get successRate =>
      totalSamples > 0 ? (successfulSamples / totalSamples) * 100 : 0.0;

  /// Device usage rate as a percentage
  double get deviceUsageRate =>
      totalSamples > 0 ? (deviceSamples / totalSamples) * 100 : 0.0;

  /// Cloud usage rate as a percentage
  double get cloudUsageRate =>
      totalSamples > 0 ? (cloudSamples / totalSamples) * 100 : 0.0;

  @override
  String toString() {
    return 'TelemetryStats('
        'samples: $totalSamples, '
        'success: ${successRate.toStringAsFixed(1)}%, '
        'device: ${deviceUsageRate.toStringAsFixed(1)}%, '
        'latency: ${avgFirstTokenLatencyMs.toStringAsFixed(0)}ms, '
        'tps: ${avgTokensPerSecond.toStringAsFixed(1)}, '
        'fps: ${avgFps.toStringAsFixed(1)})';
  }
}

/// Source of inference execution
enum InferenceSource {
  /// On-device inference using Neural Engine or CPU
  device,

  /// Cloud-based inference
  cloud,

  /// Hybrid approach (partial device, partial cloud)
  hybrid,
}
