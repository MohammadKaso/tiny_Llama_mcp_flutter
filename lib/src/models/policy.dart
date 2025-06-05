/// Policy configuration for controlling on-device vs cloud model selection
class Policy {
  const Policy._({
    required this.preferOnDevice,
    required this.maxFirstToken,
    required this.allowCloudFallback,
    required this.maxMemoryUsage,
    required this.minTokensPerSecond,
    required this.batteryThreshold,
  });

  /// Creates an auto policy that intelligently selects between device and cloud
  factory Policy.auto({
    bool preferOnDevice = true,
    Duration maxFirstToken = const Duration(milliseconds: 300),
    bool allowCloudFallback = true,
    int maxMemoryUsageGB = 4,
    double minTokensPerSecond = 10.0,
    double batteryThreshold = 0.2,
  }) {
    return Policy._(
      preferOnDevice: preferOnDevice,
      maxFirstToken: maxFirstToken,
      allowCloudFallback: allowCloudFallback,
      maxMemoryUsage:
          maxMemoryUsageGB * 1024 * 1024 * 1024, // Convert GB to bytes
      minTokensPerSecond: minTokensPerSecond,
      batteryThreshold: batteryThreshold,
    );
  }

  /// Creates a policy that forces on-device inference only
  factory Policy.deviceOnly({
    Duration maxFirstToken = const Duration(milliseconds: 500),
    int maxMemoryUsageGB = 6,
  }) {
    return Policy._(
      preferOnDevice: true,
      maxFirstToken: maxFirstToken,
      allowCloudFallback: false,
      maxMemoryUsage: maxMemoryUsageGB * 1024 * 1024 * 1024,
      minTokensPerSecond: 5.0,
      batteryThreshold: 0.0,
    );
  }

  /// Creates a policy that uses cloud models only
  factory Policy.cloudOnly() {
    return Policy._(
      preferOnDevice: false,
      maxFirstToken: const Duration(seconds: 5),
      allowCloudFallback: true,
      maxMemoryUsage: 0,
      minTokensPerSecond: 0.0,
      batteryThreshold: 1.0,
    );
  }

  /// Whether to prefer on-device models when available
  final bool preferOnDevice;

  /// Maximum acceptable time for first token generation
  final Duration maxFirstToken;

  /// Whether to allow fallback to cloud models
  final bool allowCloudFallback;

  /// Maximum memory usage in bytes for on-device models
  final int maxMemoryUsage;

  /// Minimum required tokens per second for acceptable performance
  final double minTokensPerSecond;

  /// Battery level threshold below which to prefer cloud models (0.0-1.0)
  final double batteryThreshold;

  @override
  String toString() {
    return 'Policy(preferOnDevice: $preferOnDevice, '
        'maxFirstToken: ${maxFirstToken.inMilliseconds}ms, '
        'allowCloudFallback: $allowCloudFallback, '
        'maxMemoryUsage: ${(maxMemoryUsage / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB, '
        'minTokensPerSecond: $minTokensPerSecond, '
        'batteryThreshold: $batteryThreshold)';
  }
}
