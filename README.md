# EdgeMcp_flutter

🚀 **On-device LLM inference for iOS/macOS with intelligent cloud fallback**

EdgeMcp_flutter enables seamless on-device Large Language Model inference using Apple's Neural Engine and Core ML, with automatic fallback to cloud models when device performance doesn't meet specified latency/memory targets.

## ✨ Features

- **🧠 On-Device Intelligence**: Leverages Apple's 3B "Apple Intelligence" model via Neural Engine
- **☁️ Smart Cloud Fallback**: Automatic fallback to OpenAI, Anthropic, Groq, or Gemini Pro
- **⚡ Performance Optimized**: ≤250ms first token on A17 Pro/M-series, ≤1s on iPhone 12
- **💾 Memory Efficient**: ≤4GB resident memory for default 3B 4-bit model
- **📊 Real-time Telemetry**: FPS overlay, tokens/sec, latency, and memory monitoring
- **🔒 Privacy First**: No network calls when on-device succeeds
- **🏗️ Production Ready**: Policy-based inference with comprehensive error handling

## 📱 Platform Support

| Platform | Minimum Version | Neural Engine | CPU Fallback |
|----------|----------------|---------------|--------------|
| iOS      | 18.0+          | ✅ A11+        | ✅ A11+       |
| iOS      | 15.0-17.x      | ✅ A11+        | ✅ A11+       |
| macOS    | 14.0+          | ✅ M-series     | ✅ Intel       |

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  edge_mcp_flutter: ^0.1.0
```

### Basic Usage

```dart
import 'package:edge_mcp_flutter/edge_mcp_flutter.dart';

// Initialize with auto policy
final llm = EdgeLlmIOS(
  policy: Policy.auto(
    preferOnDevice: true,
    maxFirstToken: 300.ms,
    allowCloudFallback: true,
  ),
  cloud: OpenAIConfig(apiKey: env.OAI, model: 'gpt-4o'),
);

// Generate text with streaming
final stream = llm.generate(
  prompt: 'Summarise today\'s sales orders in three bullet points.',
  system: 'You are a helpful B2B assistant.',
);

await for (final chunk in stream) {
  stdout.write(chunk);
}
```

## 🎯 Policy Configuration

### Auto Policy (Recommended)
```dart
Policy.auto(
  preferOnDevice: true,              // Try device first
  maxFirstToken: Duration(milliseconds: 300),  // Latency threshold
  allowCloudFallback: true,          // Enable cloud backup
  maxMemoryUsageGB: 4,              // Memory limit
  minTokensPerSecond: 10.0,         // Performance threshold
  batteryThreshold: 0.2,            // Min battery level
)
```

### Device-Only Policy
```dart
Policy.deviceOnly(
  maxFirstToken: Duration(milliseconds: 500),
  maxMemoryUsageGB: 6,
)
```

### Cloud-Only Policy
```dart
Policy.cloudOnly() // Always use cloud models
```

## ☁️ Cloud Providers

### OpenAI
```dart
OpenAIConfig(
  apiKey: 'your-api-key',
  model: 'gpt-4o',                  // or 'gpt-3.5-turbo'
  maxTokens: 2048,
  temperature: 0.7,
)
```

### Anthropic Claude
```dart
AnthropicConfig(
  apiKey: 'your-api-key',
  model: 'claude-3-sonnet-20240229',
  maxTokens: 2048,
)
```

### Groq
```dart
GroqConfig(
  apiKey: 'your-api-key',
  model: 'llama3-8b-8192',
  maxTokens: 2048,
)
```

### Google Gemini Pro
```dart
GeminiProConfig(
  apiKey: 'your-api-key',
  model: 'gemini-pro',
  maxTokens: 2048,
)
```

## 📊 Performance Monitoring

### Real-time Telemetry
```dart
final llm = EdgeLlmIOS(
  // ... configuration
  enableTelemetry: true,
);

// Get performance stats
final stats = llm.getStats(Duration(minutes: 5));
print('Success rate: ${stats.successRate}%');
print('Avg latency: ${stats.avgFirstTokenLatencyMs}ms');
print('Device usage: ${stats.deviceUsageRate}%');
```

### Device Capabilities
```dart
final capability = llm.deviceCapability;
print('Neural Engine: ${capability.hasNeuralEngine}');
print('Memory: ${capability.availableMemoryGB} GB');
print('Performance tier: ${capability.performanceTier}');
print('Est. latency: ${capability.estimateFirstTokenLatencyMs()}ms');
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │ ←→ │  EdgeLlmIOS API  │ ←→ │ Policy Engine   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                ↓
                    ┌──────────────────────────┐
                    │   Inference Strategy     │
                    └──────────────────────────┘
                              ↓         ↓
                   ┌─────────────────┐  ┌──────────────────┐
                   │ Native Bridge   │  │ Cloud Engine     │
                   │ (Core ML/FFI)   │  │ (HTTP/SSE)       │
                   └─────────────────┘  └──────────────────┘
                              ↓                   ↓
                   ┌─────────────────┐  ┌──────────────────┐
                   │ Neural Engine   │  │ OpenAI/Anthropic │
                   │ + Core ML       │  │ Groq/Gemini      │
                   └─────────────────┘  └──────────────────┘
```

## 🔧 Custom Models

### Apple Intelligence (Default)
- **Model**: Apple's 3B parameter model
- **Quantization**: 4-bit
- **Memory**: ~3.2GB
- **Availability**: iOS 18+ runtime-bundled

### Custom Core ML Models
```dart
EdgeLlmIOS(
  // ... other config
  onDeviceModelPath: 'path/to/your/model.mlpackage',
)
```

### Converting Models
```bash
# Using coremltools
pip install coremltools
python convert_model.py --input model.onnx --output model.mlpackage

# Using MLC-LLM
pip install mlc-llm
mlc_llm convert_weight --model-type llama --quantization q4f16_1
```

## 🛡️ Security & Privacy

- **🚫 No Network**: Zero network calls when on-device succeeds
- **🔐 Encrypted Logs**: In-memory prompt logs with AES-GCM encryption
- **🛡️ Private Relay**: Optional routing for cloud fallback requests
- **🔒 Secure Keys**: SecKeyCreateRandomKey for encryption

## 📱 Example App

Run the included example:

```bash
cd example
flutter run
```

Features:
- 📊 Real-time FPS overlay
- 📈 Performance telemetry
- 🎮 Interactive prompt testing
- 📱 Native iOS/macOS UI

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Performance Tests
```bash
# iOS Simulator
flutter drive --target=test_driver/perf_test.dart

# Physical Device
flutter drive --target=test_driver/perf_test.dart -d [device-id]
```

## 📋 Requirements

### Development
- Flutter 3.0+
- Dart 3.0+
- Xcode 15+ (iOS)
- macOS 13+ (development)

### Runtime
- iOS 15+ (CPU fallback) / iOS 18+ (Neural Engine)
- macOS 14+ (recommended for M-series)
- Memory: 4GB+ available
- Storage: 5GB+ for models

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Development Setup
```bash
git clone https://github.com/username/edge_mcp_flutter.git
cd edge_mcp_flutter
flutter pub get
cd example && flutter pub get
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Apple's Core ML team for Neural Engine APIs
- MLC-LLM project for CPU backend inspiration
- Flutter team for excellent plugin architecture
- Open source LLM community

## 📞 Support

- 📖 [Documentation](https://github.com/username/edge_mcp_flutter/wiki)
- 🐛 [Issue Tracker](https://github.com/username/edge_mcp_flutter/issues)
- 💬 [Discussions](https://github.com/username/edge_mcp_flutter/discussions)
- 📧 [Email Support](mailto:support@example.com)

---

**Made with ❤️ for the Flutter community** 