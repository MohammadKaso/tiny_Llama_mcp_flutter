# Changelog

All notable changes to the EdgeMcp_flutter package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-01-20

### Added
- 🚀 Initial release of EdgeMcp_flutter package
- 🧠 On-device LLM inference using Apple's Neural Engine and Core ML
- ☁️ Intelligent cloud fallback to OpenAI, Anthropic, Groq, and Gemini Pro
- 📊 Real-time performance telemetry and monitoring
- 🎯 Policy-based inference strategy selection
- 📱 iOS 15+ and macOS 14+ support
- 🔒 Privacy-first design with encrypted logging
- 📈 FPS overlay and performance metrics
- 🎮 Beautiful sample app with native iOS/macOS UI

### Core Features
- **EdgeLlmIOS**: Main class for LLM inference with device/cloud selection
- **Policy**: Auto, device-only, and cloud-only inference policies
- **ModelCapability**: Device capability assessment and performance estimation
- **Telemetry**: Real-time performance monitoring and statistics
- **CloudConfig**: Support for multiple cloud providers with streaming
- **NativeEdgeLlmBridge**: FFI bridge for Core ML integration

### Platform Support
- iOS 18+ with Neural Engine support
- iOS 15-17 with CPU fallback
- macOS 14+ with M-series optimization
- Intel Mac support with CPU inference

### Performance Targets
- ≤250ms first token latency on A17 Pro/M-series
- ≤1s first token latency on iPhone 12 with CPU
- ≤4GB memory usage for 3B 4-bit model
- Real-time FPS monitoring and telemetry

### Cloud Providers
- OpenAI (GPT-4o, GPT-3.5-turbo) with streaming
- Anthropic Claude (Sonnet, Haiku) with SSE
- Groq (Llama3, Mixtral) with high-speed inference
- Google Gemini Pro with streaming support

### Security & Privacy
- Zero network calls when on-device succeeds
- AES-GCM encrypted in-memory prompt logs
- Optional Private Relay routing for cloud requests
- SecKeyCreateRandomKey for encryption keys

### Developer Experience
- Comprehensive documentation and examples
- Flutter-native API design
- Type-safe configuration
- Detailed error messages and telemetry
- Beautiful sample app demonstrating features

## [Unreleased]

### Planned Features
- 🔄 Model switching and hot-swapping
- 📦 Custom Core ML model loading (.mlpackage)
- 🧪 MLC-LLM integration for broader model support
- 🔧 Advanced quantization options (8-bit, 16-bit)
- 📊 Enhanced telemetry with battery impact tracking
- 🌐 Additional cloud providers (Cohere, Together AI)
- 🎯 Fine-tuning support for custom models
- 📱 watchOS companion app for telemetry
- 🔍 Model benchmarking and comparison tools
- 📈 Performance profiling and optimization guides

### Known Issues
- HTTP package dependency needs `flutter pub get`
- Simulator testing limited without Neural Engine
- Large model downloads require Wi-Fi connection
- Background inference limited by iOS app lifecycle

---

For migration guides and detailed release notes, see our [Documentation](https://github.com/username/edge_mcp_flutter/wiki). 