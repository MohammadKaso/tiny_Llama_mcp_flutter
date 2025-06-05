import 'dart:async';
import 'package:flutter/services.dart';

/// Platform channel bridge to native iOS implementation for on-device LLM inference
class NativeEdgeLlmBridge {
  static const MethodChannel _channel = MethodChannel('edge_mcp_flutter');

  bool _isInitialized = false;

  /// Initialize the native Core ML model
  Future<void> initialize({
    required String modelPath,
  }) async {
    if (_isInitialized) return;

    try {
      final result = await _channel.invokeMethod('initializeModel', {
        'modelPath': modelPath,
      });

      if (result['success'] == true) {
        _isInitialized = true;
        print(
            'Native bridge initialized: ${result['framework']} - ${result['modelSize']}');
      } else {
        throw Exception(
            'Failed to initialize model: ${result['error'] ?? 'Unknown error'}');
      }
    } on PlatformException catch (e) {
      throw Exception('Platform error during initialization: ${e.message}');
    } catch (e) {
      throw Exception('Failed to initialize native bridge: $e');
    }
  }

  /// Generate text using the native on-device model
  Stream<String> generate({
    required String prompt,
    String? system,
    required int maxTokens,
    required double temperature,
  }) async* {
    try {
      print('🌉 NativeEdgeLlmBridge.generate called');
      print('📝 Prompt: "$prompt"');
      print('⚙️ System: "$system"');
      print('🎛️ MaxTokens: $maxTokens, Temperature: $temperature');

      final result = await _channel.invokeMethod('generateText', {
        'prompt': prompt,
        'systemPrompt': system,
        'maxTokens': maxTokens,
        'temperature': temperature,
      });

      print('✅ Native method call completed');
      print('🔍 Result type: ${result.runtimeType}');
      print('📊 Result: $result');

      if (result == null) {
        print('❌ Result is null');
        throw Exception('No response from native layer');
      }

      final tokens = result['tokens'] as List<dynamic>?;
      if (tokens == null) {
        print('❌ No tokens in result');
        throw Exception('No tokens returned from native layer');
      }

      print('✅ Got ${tokens.length} tokens from native layer');

      // Stream the tokens
      for (final token in tokens) {
        yield token.toString();
      }

      print('✅ NativeEdgeLlmBridge.generate completed successfully');
    } catch (e) {
      print('❌ NativeEdgeLlmBridge.generate failed: $e');
      print('🔍 Error type: ${e.runtimeType}');
      throw Exception('Failed to generate text: $e');
    }
  }

  /// Get model information
  Future<Map<String, dynamic>> getModelInfo() async {
    if (!_isInitialized) {
      throw StateError('Native bridge not initialized');
    }

    try {
      final result = await _channel.invokeMethod('getModelInfo');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Platform error getting model info: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get model info: $e');
    }
  }

  /// Get device capabilities
  Future<Map<String, dynamic>> getDeviceCapabilities() async {
    try {
      final result = await _channel.invokeMethod('getDeviceCapabilities');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Platform error getting capabilities: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get device capabilities: $e');
    }
  }

  /// Check if model is loaded and ready
  bool get isReady => _isInitialized;

  /// Dispose native resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('disposeModel');
      _isInitialized = false;
      print('Native bridge disposed');
    } on PlatformException catch (e) {
      print('Warning: Error disposing native bridge: ${e.message}');
    } catch (e) {
      print('Warning: Error disposing native bridge: $e');
    }
  }
}

/// Native callback handler for streaming tokens
class NativeTokenCallback {
  NativeTokenCallback(this._controller);

  final StreamController<String> _controller;

  /// Handle token from native callback
  void onToken(String token) {
    if (!_controller.isClosed) {
      _controller.add(token);
    }
  }

  /// Handle error from native callback
  void onError(String error) {
    if (!_controller.isClosed) {
      _controller.addError(Exception(error));
    }
  }

  /// Handle completion from native callback
  void onComplete() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
