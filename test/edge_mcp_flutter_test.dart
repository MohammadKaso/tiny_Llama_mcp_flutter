import 'package:flutter_test/flutter_test.dart';
import 'package:edge_mcp_flutter/edge_mcp_flutter.dart';

void main() {
  group('Policy Tests', () {
    test('Policy.auto creates correct configuration', () {
      final policy = Policy.auto(
        preferOnDevice: true,
        maxFirstToken: const Duration(milliseconds: 300),
        allowCloudFallback: true,
        maxMemoryUsageGB: 4,
        minTokensPerSecond: 10.0,
        batteryThreshold: 0.2,
      );

      expect(policy.preferOnDevice, isTrue);
      expect(policy.maxFirstToken.inMilliseconds, equals(300));
      expect(policy.allowCloudFallback, isTrue);
      expect(policy.maxMemoryUsage, equals(4 * 1024 * 1024 * 1024));
      expect(policy.minTokensPerSecond, equals(10.0));
      expect(policy.batteryThreshold, equals(0.2));
    });

    test('Policy.deviceOnly creates device-only configuration', () {
      final policy = Policy.deviceOnly(
        maxFirstToken: const Duration(milliseconds: 500),
        maxMemoryUsageGB: 6,
      );

      expect(policy.preferOnDevice, isTrue);
      expect(policy.allowCloudFallback, isFalse);
      expect(policy.maxFirstToken.inMilliseconds, equals(500));
      expect(policy.maxMemoryUsage, equals(6 * 1024 * 1024 * 1024));
    });

    test('Policy.cloudOnly creates cloud-only configuration', () {
      final policy = Policy.cloudOnly();

      expect(policy.preferOnDevice, isFalse);
      expect(policy.allowCloudFallback, isTrue);
      expect(policy.batteryThreshold, equals(1.0));
    });

    test('Policy toString provides readable output', () {
      final policy = Policy.auto();
      final str = policy.toString();

      expect(str, contains('Policy'));
      expect(str, contains('preferOnDevice'));
      expect(str, contains('maxFirstToken'));
      expect(str, contains('allowCloudFallback'));
    });
  });

  group('CloudConfig Tests', () {
    test('OpenAIConfig creates correct configuration', () {
      const config = OpenAIConfig(
        apiKey: 'test-key',
        model: 'gpt-4o',
        maxTokens: 2048,
        temperature: 0.7,
      );

      expect(config.provider, equals('openai'));
      expect(config.model, equals('gpt-4o'));
      expect(config.apiKey, equals('test-key'));
      expect(config.maxTokens, equals(2048));
      expect(config.temperature, equals(0.7));
      expect(config.endpoint, contains('openai.com'));
    });

    test('OpenAIConfig creates correct headers', () {
      const config = OpenAIConfig(apiKey: 'test-key');
      final headers = config.toHeaders();

      expect(headers['Authorization'], equals('Bearer test-key'));
      expect(headers['Content-Type'], equals('application/json'));
    });

    test('OpenAIConfig creates correct request body', () {
      const config = OpenAIConfig(apiKey: 'test-key', model: 'gpt-4o');
      final body = config.toRequestBody('Hello', 'You are helpful');

      expect(body['model'], equals('gpt-4o'));
      expect(body['messages'], isA<List>());
      expect(body['stream'], isTrue);

      final messages = body['messages'] as List;
      expect(messages.length, equals(2));
      expect(messages[0]['role'], equals('system'));
      expect(messages[0]['content'], equals('You are helpful'));
      expect(messages[1]['role'], equals('user'));
      expect(messages[1]['content'], equals('Hello'));
    });

    test('AnthropicConfig creates correct configuration', () {
      const config = AnthropicConfig(
        apiKey: 'test-key',
        model: 'claude-3-sonnet-20240229',
      );

      expect(config.provider, equals('anthropic'));
      expect(config.model, equals('claude-3-sonnet-20240229'));
      expect(config.endpoint, contains('anthropic.com'));
    });

    test('GroqConfig creates correct configuration', () {
      const config = GroqConfig(
        apiKey: 'test-key',
        model: 'llama3-8b-8192',
      );

      expect(config.provider, equals('groq'));
      expect(config.model, equals('llama3-8b-8192'));
      expect(config.endpoint, contains('groq.com'));
    });

    test('GeminiProConfig creates correct configuration', () {
      const config = GeminiProConfig(
        apiKey: 'test-key',
        model: 'gemini-pro',
      );

      expect(config.provider, equals('gemini'));
      expect(config.model, equals('gemini-pro'));
      expect(config.endpoint, contains('generativelanguage.googleapis.com'));
    });
  });

  group('ModelCapability Tests', () {
    test('ModelCapability.evaluate returns valid capability', () async {
      final capability = await ModelCapability.evaluate();

      expect(capability.hasNeuralEngine, isA<bool>());
      expect(capability.availableMemoryGB, greaterThan(0));
      expect(capability.deviceModel, isNotEmpty);
      expect(capability.osVersion, isNotEmpty);
      expect(capability.batteryLevel, inInclusiveRange(0.0, 1.0));
      expect(capability.cpuCoreCount, greaterThan(0));
      expect(capability.isLowPowerMode, isA<bool>());
    });

    test('ModelCapability can assess model requirements', () async {
      final capability = await ModelCapability.evaluate();

      // Test with reasonable model requirements
      final canHandle = capability.canHandleModel(
        modelSizeGB: 3.0,
        memoryOverheadGB: 1.0,
        minBatteryLevel: 0.1,
      );

      expect(canHandle, isA<bool>());
    });

    test('ModelCapability performance estimation is reasonable', () async {
      final capability = await ModelCapability.evaluate();

      final latency = capability.estimateFirstTokenLatencyMs();
      final tps = capability.estimateTokensPerSecond();

      expect(latency, greaterThan(0));
      expect(latency, lessThan(5000)); // Should be less than 5 seconds
      expect(tps, greaterThan(0));
      expect(tps, lessThan(100)); // Reasonable upper bound
    });

    test('ModelCapability toString provides readable output', () async {
      final capability = await ModelCapability.evaluate();
      final str = capability.toString();

      expect(str, contains('ModelCapability'));
      expect(str, contains('tier'));
      expect(str, contains('neuralEngine'));
      expect(str, contains('memory'));
      expect(str, contains('device'));
    });
  });

  group('Telemetry Tests', () {
    test('Telemetry constructor creates valid instance', () {
      final telemetry = Telemetry(
        timestamp: DateTime.now(),
        source: InferenceSource.device,
        firstTokenLatencyMs: 150,
        tokensPerSecond: 15.0,
        memoryUsageBytes: 3 * 1024 * 1024 * 1024, // 3GB
        batteryDrainPercent: 0.1,
        cpuUsagePercent: 50.0,
        fps: 60.0,
      );

      expect(telemetry.source, equals(InferenceSource.device));
      expect(telemetry.firstTokenLatencyMs, equals(150));
      expect(telemetry.tokensPerSecond, equals(15.0));
      expect(telemetry.memoryUsageGB, closeTo(3.0, 0.1));
      expect(telemetry.isSuccess, isTrue);
      expect(telemetry.meetsPerformanceTargets, isTrue);
    });

    test('Telemetry with error message marks as failure', () {
      final telemetry = Telemetry(
        timestamp: DateTime.now(),
        source: InferenceSource.cloud,
        firstTokenLatencyMs: 500,
        tokensPerSecond: 5.0,
        memoryUsageBytes: 1024 * 1024 * 1024, // 1GB
        batteryDrainPercent: 0.2,
        cpuUsagePercent: 30.0,
        fps: 30.0,
        errorMessage: 'Network timeout',
      );

      expect(telemetry.isSuccess, isFalse);
      expect(telemetry.errorMessage, equals('Network timeout'));
    });

    test('Telemetry JSON serialization works correctly', () {
      final original = Telemetry(
        timestamp: DateTime.parse('2024-01-20T12:00:00Z'),
        source: InferenceSource.device,
        firstTokenLatencyMs: 200,
        tokensPerSecond: 12.5,
        memoryUsageBytes: 2 * 1024 * 1024 * 1024, // 2GB
        batteryDrainPercent: 0.15,
        cpuUsagePercent: 45.0,
        fps: 55.0,
      );

      final json = original.toJson();
      final restored = Telemetry.fromJson(json);

      expect(restored.timestamp, equals(original.timestamp));
      expect(restored.source, equals(original.source));
      expect(
          restored.firstTokenLatencyMs, equals(original.firstTokenLatencyMs));
      expect(restored.tokensPerSecond, equals(original.tokensPerSecond));
      expect(restored.memoryUsageBytes, equals(original.memoryUsageBytes));
      expect(
          restored.batteryDrainPercent, equals(original.batteryDrainPercent));
      expect(restored.cpuUsagePercent, equals(original.cpuUsagePercent));
      expect(restored.fps, equals(original.fps));
      expect(restored.errorMessage, equals(original.errorMessage));
    });
  });

  group('TelemetryAggregator Tests', () {
    test('TelemetryAggregator starts empty', () {
      final aggregator = TelemetryAggregator();

      expect(aggregator.samples, isEmpty);
      final stats = aggregator.getStats();
      expect(stats.totalSamples, equals(0));
    });

    test('TelemetryAggregator adds samples correctly', () {
      final aggregator = TelemetryAggregator();

      final sample = Telemetry(
        timestamp: DateTime.now(),
        source: InferenceSource.device,
        firstTokenLatencyMs: 150,
        tokensPerSecond: 15.0,
        memoryUsageBytes: 3 * 1024 * 1024 * 1024,
        batteryDrainPercent: 0.1,
        cpuUsagePercent: 50.0,
        fps: 60.0,
      );

      aggregator.addSample(sample);

      expect(aggregator.samples.length, equals(1));
      expect(aggregator.samples.first, equals(sample));
    });

    test('TelemetryAggregator calculates stats correctly', () {
      final aggregator = TelemetryAggregator();

      // Add successful device sample
      aggregator.addSample(Telemetry(
        timestamp: DateTime.now(),
        source: InferenceSource.device,
        firstTokenLatencyMs: 150,
        tokensPerSecond: 15.0,
        memoryUsageBytes: 3 * 1024 * 1024 * 1024,
        batteryDrainPercent: 0.1,
        cpuUsagePercent: 50.0,
        fps: 60.0,
      ));

      // Add successful cloud sample
      aggregator.addSample(Telemetry(
        timestamp: DateTime.now(),
        source: InferenceSource.cloud,
        firstTokenLatencyMs: 300,
        tokensPerSecond: 10.0,
        memoryUsageBytes: 1 * 1024 * 1024 * 1024,
        batteryDrainPercent: 0.05,
        cpuUsagePercent: 30.0,
        fps: 55.0,
      ));

      final stats = aggregator.getStats();

      expect(stats.totalSamples, equals(2));
      expect(stats.successfulSamples, equals(2));
      expect(stats.deviceSamples, equals(1));
      expect(stats.cloudSamples, equals(1));
      expect(stats.successRate, equals(100.0));
      expect(stats.deviceUsageRate, equals(50.0));
      expect(stats.cloudUsageRate, equals(50.0));
      expect(stats.avgFirstTokenLatencyMs, equals(225.0)); // (150 + 300) / 2
      expect(stats.avgTokensPerSecond, equals(12.5)); // (15 + 10) / 2
    });

    test('TelemetryAggregator limits sample count', () {
      final aggregator = TelemetryAggregator();

      // Add more than max samples
      for (int i = 0; i < 150; i++) {
        aggregator.addSample(Telemetry(
          timestamp: DateTime.now(),
          source: InferenceSource.device,
          firstTokenLatencyMs: 150,
          tokensPerSecond: 15.0,
          memoryUsageBytes: 3 * 1024 * 1024 * 1024,
          batteryDrainPercent: 0.1,
          cpuUsagePercent: 50.0,
          fps: 60.0,
        ));
      }

      expect(aggregator.samples.length, equals(100)); // Should be capped at max
    });
  });

  group('Exception Tests', () {
    test('EdgeLlmException has correct message and details', () {
      const exception = ModelLoadException('Model not found', 'File missing');

      expect(exception.message, equals('Model not found'));
      expect(exception.details, equals('File missing'));
      expect(exception.toString(), contains('Model not found'));
      expect(exception.toString(), contains('File missing'));
    });

    test('Exception hierarchy is correct', () {
      const modelException = ModelLoadException('Test');
      const generationException = GenerationException('Test');
      const configException = ConfigurationException('Test');
      const cloudException = CloudFallbackException('Test');
      const capabilityException = InsufficientCapabilityException('Test');

      expect(modelException, isA<EdgeLlmException>());
      expect(generationException, isA<EdgeLlmException>());
      expect(configException, isA<EdgeLlmException>());
      expect(cloudException, isA<EdgeLlmException>());
      expect(capabilityException, isA<EdgeLlmException>());
    });
  });
}
