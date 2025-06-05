import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/cloud_config.dart';
import '../exceptions/edge_llm_exception.dart';

/// Cloud inference engine for handling fallback to cloud models
class CloudInferenceEngine {
  CloudInferenceEngine(this.config) : _client = http.Client();

  final CloudConfig config;
  final http.Client _client;

  /// Generate text stream using cloud model
  Stream<String> generate({
    required String prompt,
    String? system,
    int? maxTokens,
    double? temperature,
  }) async* {
    try {
      final request = http.Request('POST', Uri.parse(config.endpoint));

      // Set headers
      request.headers.addAll(config.toHeaders());

      // Set request body
      final body = config.toRequestBody(prompt, system);

      // Override temperature and maxTokens if provided
      if (temperature != null && body.containsKey('temperature')) {
        body['temperature'] = temperature;
      }
      if (maxTokens != null) {
        if (body.containsKey('max_tokens')) {
          body['max_tokens'] = maxTokens;
        } else if (body.containsKey('generationConfig')) {
          (body['generationConfig']
                  as Map<String, dynamic>)['maxOutputTokens'] =
              maxTokens;
        }
      }

      request.body = jsonEncode(body);

      if (config.streamingEnabled) {
        yield* _handleStreamingResponse(request);
      } else {
        yield* _handleNonStreamingResponse(request);
      }
    } catch (e) {
      throw CloudFallbackException(
        'Failed to generate text using ${config.provider}',
        e.toString(),
      );
    }
  }

  /// Handle streaming SSE response
  Stream<String> _handleStreamingResponse(http.Request request) async* {
    try {
      final response = await _client.send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw CloudFallbackException(
          'Cloud API returned status ${response.statusCode}',
          errorBody,
        );
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');

        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          String? token;

          switch (config.provider) {
            case 'openai':
            case 'groq':
              token = _parseOpenAIStreamChunk(line);
              break;
            case 'anthropic':
              token = _parseAnthropicStreamChunk(line);
              break;
            case 'gemini':
              token = _parseGeminiStreamChunk(line);
              break;
          }

          if (token != null && token.isNotEmpty) {
            yield token;
          }
        }
      }
    } catch (e) {
      throw CloudFallbackException(
        'Streaming error with ${config.provider}',
        e.toString(),
      );
    }
  }

  /// Handle non-streaming response
  Stream<String> _handleNonStreamingResponse(http.Request request) async* {
    try {
      final response = await _client.send(request);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw CloudFallbackException(
          'Cloud API returned status ${response.statusCode}',
          responseBody,
        );
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      String? content;

      switch (config.provider) {
        case 'openai':
        case 'groq':
          content = _extractOpenAIContent(json);
          break;
        case 'anthropic':
          content = _extractAnthropicContent(json);
          break;
        case 'gemini':
          content = _extractGeminiContent(json);
          break;
      }

      if (content != null) {
        // Simulate streaming by yielding words one by one
        final words = content.split(' ');
        for (int i = 0; i < words.length; i++) {
          yield words[i];
          if (i < words.length - 1) yield ' ';

          // Small delay to simulate streaming
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      throw CloudFallbackException(
        'Non-streaming error with ${config.provider}',
        e.toString(),
      );
    }
  }

  /// Parse OpenAI/Groq streaming chunk
  String? _parseOpenAIStreamChunk(String line) {
    if (!line.startsWith('data: ')) return null;

    final data = line.substring(6).trim();
    if (data == '[DONE]') return null;

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices?.isNotEmpty == true) {
        final delta = choices![0]['delta'] as Map<String, dynamic>?;
        return delta?['content'] as String?;
      }
    } catch (e) {
      // Invalid JSON, skip this chunk
    }

    return null;
  }

  /// Parse Anthropic streaming chunk
  String? _parseAnthropicStreamChunk(String line) {
    if (!line.startsWith('data: ')) return null;

    final data = line.substring(6).trim();

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'content_block_delta') {
        final delta = json['delta'] as Map<String, dynamic>?;
        return delta?['text'] as String?;
      }
    } catch (e) {
      // Invalid JSON, skip this chunk
    }

    return null;
  }

  /// Parse Gemini streaming chunk
  String? _parseGeminiStreamChunk(String line) {
    if (!line.startsWith('data: ')) return null;

    final data = line.substring(6).trim();

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;

      if (candidates?.isNotEmpty == true) {
        final content = candidates![0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;

        if (parts?.isNotEmpty == true) {
          return parts![0]['text'] as String?;
        }
      }
    } catch (e) {
      // Invalid JSON, skip this chunk
    }

    return null;
  }

  /// Extract content from OpenAI/Groq non-streaming response
  String? _extractOpenAIContent(Map<String, dynamic> json) {
    final choices = json['choices'] as List<dynamic>?;
    if (choices?.isNotEmpty == true) {
      final message = choices![0]['message'] as Map<String, dynamic>?;
      return message?['content'] as String?;
    }
    return null;
  }

  /// Extract content from Anthropic non-streaming response
  String? _extractAnthropicContent(Map<String, dynamic> json) {
    final content = json['content'] as List<dynamic>?;
    if (content?.isNotEmpty == true) {
      return content![0]['text'] as String?;
    }
    return null;
  }

  /// Extract content from Gemini non-streaming response
  String? _extractGeminiContent(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates?.isNotEmpty == true) {
      final content = candidates![0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;

      if (parts?.isNotEmpty == true) {
        return parts![0]['text'] as String?;
      }
    }
    return null;
  }

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }
}
