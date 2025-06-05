/// Base exception class for EdgeMcp_flutter package
abstract class EdgeLlmException implements Exception {
  const EdgeLlmException(this.message, [this.details]);

  final String message;
  final String? details;

  @override
  String toString() =>
      'EdgeLlmException: $message${details != null ? ' ($details)' : ''}';
}

/// Exception thrown when device capabilities are insufficient
class InsufficientCapabilityException extends EdgeLlmException {
  const InsufficientCapabilityException(String message, [String? details])
    : super(message, details);
}

/// Exception thrown when model loading fails
class ModelLoadException extends EdgeLlmException {
  const ModelLoadException(String message, [String? details])
    : super(message, details);
}

/// Exception thrown when generation fails
class GenerationException extends EdgeLlmException {
  const GenerationException(String message, [String? details])
    : super(message, details);
}

/// Exception thrown when cloud fallback fails
class CloudFallbackException extends EdgeLlmException {
  const CloudFallbackException(String message, [String? details])
    : super(message, details);
}

/// Exception thrown when configuration is invalid
class ConfigurationException extends EdgeLlmException {
  const ConfigurationException(String message, [String? details])
    : super(message, details);
}
