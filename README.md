# edge_mcp_flutter

🚀 **On-device LLM inference for iOS/macOS with intelligent cloud fallback**

edge_mcp_flutter enables seamless on-device Large Language Model inference using Apple's Neural Engine and Core ML, with automatic fallback to cloud models when device performance doesn't meet specified latency/memory targets.

## ✨ Features

- **🧠 On-Device Intelligence**: Leverages MLC-LLM with optimized 3B parameter models via Neural Engine
- **☁️ Smart Cloud Fallback**: Automatic fallback to OpenAI, Anthropic, Groq, or Gemini Pro
- **⚡ Performance Optimized**: ≤250ms first token on A17 Pro/M-series, ≤1s on iPhone 12
- **💾 Memory Efficient**: ≤4GB resident memory for default 3B 4-bit quantized model
- **📊 Real-time Telemetry**: Live FPS overlay, tokens/sec, latency, and memory monitoring
- **🔒 Privacy First**: No network calls when on-device succeeds
- **🏗️ Production Ready**: Policy-based inference with comprehensive error handling

## 📱 Platform Support

| Platform | Minimum Version | Neural Engine | CPU Fallback |
|----------|----------------|---------------|--------------|
| iOS      | 15.0+          | ✅ A11+        | ✅ A11+       |
| macOS    | 12.0+          | ✅ M-series     | ✅ Intel       |

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

void main() async {
  // Initialize with auto policy
  final llm = EdgeLlmIOS(
    policy: Policy.auto(
      preferOnDevice: true,
      maxFirstToken: const Duration(milliseconds: 500),
      allowCloudFallback: true,
    ),
    cloud: const OpenAIConfig(
      apiKey: 'your-openai-api-key',
      model: 'gpt-4o',
    ),
    enableTelemetry: true,
  );

  // Initialize the engine
  await llm.initialize();

  // Generate text with streaming
  final stream = llm.generate(
    prompt: 'Explain quantum computing in simple terms.',
    system: 'You are a helpful assistant that explains complex topics clearly.',
  );

  await for (final chunk in stream) {
    print(chunk);
  }
}
```

## 🎯 Policy Configuration

### Auto Policy (Recommended)
```dart
Policy.auto(
  preferOnDevice: true,                              // Try device first
  maxFirstToken: const Duration(milliseconds: 500), // Latency threshold
  allowCloudFallback: true,                         // Enable cloud backup
  maxMemoryUsageGB: 4.0,                           // Memory limit
  minTokensPerSecond: 8.0,                         // Performance threshold
  batteryThreshold: 0.15,                          // Min battery level
)
```

### Device-Only Policy
```dart
Policy.deviceOnly(
  maxFirstToken: const Duration(milliseconds: 1000),
  maxMemoryUsageGB: 6.0,
)
```

### Cloud-Only Policy
```dart
Policy.cloudOnly() // Always use cloud models
```

## ☁️ Cloud Providers

### OpenAI
```dart
const OpenAIConfig(
  apiKey: 'your-api-key',
  model: 'gpt-4o',                  // or 'gpt-3.5-turbo'
  maxTokens: 2048,
  temperature: 0.7,
)
```

### Anthropic Claude
```dart
const AnthropicConfig(
  apiKey: 'your-api-key',
  model: 'claude-3-sonnet-20240229',
  maxTokens: 2048,
  temperature: 0.7,
)
```

### Groq
```dart
const GroqConfig(
  apiKey: 'your-api-key',
  model: 'llama3-8b-8192',
  maxTokens: 2048,
  temperature: 0.7,
)
```

### Google Gemini Pro
```dart
const GeminiProConfig(
  apiKey: 'your-api-key',
  model: 'gemini-pro',
  maxTokens: 2048,
  temperature: 0.7,
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
final stats = llm.getStats(const Duration(minutes: 5));
print('Success rate: ${stats.successRate}%');
print('Avg latency: ${stats.avgFirstTokenLatencyMs}ms');
print('Device usage: ${stats.deviceUsageRate}%');
```

### Device Capabilities
```dart
await llm.initialize();
final capability = llm.deviceCapability;
print('Neural Engine: ${capability.hasNeuralEngine}');
print('Memory: ${capability.availableMemoryGB} GB');
print('Performance tier: ${capability.performanceTier}');
print('Est. latency: ${capability.estimateFirstTokenLatencyMs()}ms');
print('Device model: ${capability.deviceModel}');
print('CPU cores: ${capability.cpuCoreCount}');
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
                   │ (MLC-LLM/FFI)   │  │ (HTTP/SSE)       │
                   └─────────────────┘  └──────────────────┘
                              ↓                   ↓
                   ┌─────────────────┐  ┌──────────────────┐
                   │ Neural Engine   │  │ OpenAI/Anthropic │
                   │ + Core ML       │  │ Groq/Gemini      │
                   └─────────────────┘  └──────────────────┘
```

## 🔧 Custom Models

### MLC-LLM Models (Default)
- **Framework**: MLC-LLM with TVM optimization
- **Quantization**: 4-bit, 8-bit, and 16-bit support
- **Memory**: 2-8GB depending on model size
- **Models**: Llama2, Llama3, Mistral, Phi, and custom models

### Using Custom Models
```dart
EdgeLlmIOS(
  // ... other config
  modelPath: 'path/to/your/mlc-model',
  modelConfig: 'path/to/mlc-chat-config.json',
)
```

### Converting Models to MLC Format
```bash
# Install MLC-LLM
pip install mlc-llm

# Convert a Hugging Face model
mlc_llm convert_weight \
  --model HuggingFaceModel/model-name \
  --quantization q4f16_1 \
  --output ./converted_model

# Compile for iOS
mlc_llm compile \
  --model ./converted_model \
  --target iphone \
  --output ./ios_model
```

## 🛡️ Security & Privacy

- **🚫 No Network**: Zero network calls when on-device inference succeeds
- **🔐 Local Processing**: All on-device computation stays on device
- **🛡️ Encrypted Memory**: Secure memory handling for sensitive prompts
- **🔒 API Security**: Secure API key management for cloud fallback

## 📱 Example App

The included example app demonstrates all features:

```bash
cd example
flutter run
```

**Features:**
- 📊 Real-time FPS monitoring overlay
- 📈 Live performance telemetry display
- 🎮 Interactive prompt testing interface
- 📱 Native iOS/macOS optimized UI
- 🔄 Policy switching demonstration
- 📊 Device capability inspection

## 📦 Project Structure

```
edge_mcp_flutter/
├── lib/
│   ├── edge_mcp_flutter.dart      # Main library export
│   └── src/
│       ├── edge_llm_ios.dart      # Core EdgeLlmIOS class
│       ├── models/                # Data models
│       │   ├── policy.dart        # Inference policies
│       │   ├── cloud_config.dart  # Cloud provider configs
│       │   ├── model_capability.dart # Device capabilities
│       │   └── telemetry.dart     # Performance monitoring
│       ├── cloud/                 # Cloud provider implementations
│       ├── ffi/                   # Native bridge
│       └── exceptions/            # Error handling
├── ios/                          # iOS platform implementation
│   ├── Classes/
│   │   ├── EdgeMcpFlutterPlugin.swift  # Flutter plugin
│   │   ├── MLCLlamaEngine.swift       # MLC-LLM engine
│   │   ├── MLCBridge.h/.mm           # C++ bridge
│   │   └── EdgeMcpFlutter.h          # Headers
│   ├── MLCSwift/                     # MLC Swift framework
│   └── model/                        # Pre-built models
├── macos/                           # macOS platform implementation
├── example/                         # Demo application
└── test/                           # Test suite
```

## 📋 Requirements

### Development
- Flutter 3.0+
- Dart 3.0+
- Xcode 14+ (iOS/macOS)
- CocoaPods 1.11+

### Runtime
- iOS 15+ / macOS 12+
- Memory: 4GB+ available RAM
- Storage: 3-8GB for models (varies by model size)
- Neural Engine: A11+ (iPhone X+) / M-series (recommended)

## 🚀 Getting Started

1. **Add dependency:**
   ```yaml
   dependencies:
     edge_mcp_flutter: ^0.1.0
   ```

2. **Initialize in your app:**
   ```dart
   final llm = EdgeLlmIOS(
     policy: Policy.auto(preferOnDevice: true),
     cloud: const OpenAIConfig(apiKey: 'your-key'),
   );
   await llm.initialize();
   ```

3. **Generate text:**
   ```dart
   final stream = llm.generate(prompt: 'Hello, world!');
   await for (final token in stream) {
     print(token);
   }
   ```

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [GitHub Repository](https://github.com/mohammad/edge_mcp_flutter)
- [API Documentation](https://pub.dev/documentation/edge_mcp_flutter)
- [Example App](./example/)
- [MLC-LLM Documentation](https://mlc.ai/mlc-llm/)

## 📞 Support

- 🐛 [Report Issues](https://github.com/mohammad/edge_mcp_flutter/issues)
- 💬 [Discussions](https://github.com/mohammad/edge_mcp_flutter/discussions)
- 📧 [Email Support](mailto:support@example.com)
