/// Base class for cloud model configurations
abstract class CloudConfig {
  const CloudConfig({
    required this.provider,
    required this.model,
    required this.apiKey,
    this.baseUrl,
    this.maxTokens = 2048,
    this.temperature = 0.7,
    this.streamingEnabled = true,
  });

  final String provider;
  final String model;
  final String apiKey;
  final String? baseUrl;
  final int maxTokens;
  final double temperature;
  final bool streamingEnabled;

  Map<String, String> toHeaders();
  Map<String, dynamic> toRequestBody(String prompt, String? system);
  String get endpoint;
}

/// OpenAI API configuration
class OpenAIConfig extends CloudConfig {
  const OpenAIConfig({
    required String apiKey,
    String model = 'gpt-4o',
    String? baseUrl,
    int maxTokens = 2048,
    double temperature = 0.7,
    bool streamingEnabled = true,
  }) : super(
          provider: 'openai',
          model: model,
          apiKey: apiKey,
          baseUrl: baseUrl,
          maxTokens: maxTokens,
          temperature: temperature,
          streamingEnabled: streamingEnabled,
        );

  @override
  String get endpoint =>
      '${baseUrl ?? 'https://api.openai.com'}/v1/chat/completions';

  @override
  Map<String, String> toHeaders() => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  @override
  Map<String, dynamic> toRequestBody(String prompt, String? system) {
    final messages = <Map<String, dynamic>>[];
    if (system != null) {
      messages.add({'role': 'system', 'content': system});
    }
    messages.add({'role': 'user', 'content': prompt});

    return {
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': streamingEnabled,
    };
  }
}

/// Anthropic API configuration
class AnthropicConfig extends CloudConfig {
  const AnthropicConfig({
    required String apiKey,
    String model = 'claude-3-sonnet-20240229',
    String? baseUrl,
    int maxTokens = 2048,
    double temperature = 0.7,
    bool streamingEnabled = true,
  }) : super(
          provider: 'anthropic',
          model: model,
          apiKey: apiKey,
          baseUrl: baseUrl,
          maxTokens: maxTokens,
          temperature: temperature,
          streamingEnabled: streamingEnabled,
        );

  @override
  String get endpoint =>
      '${baseUrl ?? 'https://api.anthropic.com'}/v1/messages';

  @override
  Map<String, String> toHeaders() => {
        'x-api-key': apiKey,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
      };

  @override
  Map<String, dynamic> toRequestBody(String prompt, String? system) {
    final messages = [
      {'role': 'user', 'content': prompt},
    ];

    final body = {
      'model': model,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'messages': messages,
      'stream': streamingEnabled,
    };

    if (system != null) {
      body['system'] = system;
    }

    return body;
  }
}

/// Groq API configuration
class GroqConfig extends CloudConfig {
  const GroqConfig({
    required String apiKey,
    String model = 'llama3-8b-8192',
    String? baseUrl,
    int maxTokens = 2048,
    double temperature = 0.7,
    bool streamingEnabled = true,
  }) : super(
          provider: 'groq',
          model: model,
          apiKey: apiKey,
          baseUrl: baseUrl,
          maxTokens: maxTokens,
          temperature: temperature,
          streamingEnabled: streamingEnabled,
        );

  @override
  String get endpoint =>
      '${baseUrl ?? 'https://api.groq.com'}/openai/v1/chat/completions';

  @override
  Map<String, String> toHeaders() => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  @override
  Map<String, dynamic> toRequestBody(String prompt, String? system) {
    final messages = <Map<String, dynamic>>[];
    if (system != null) {
      messages.add({'role': 'system', 'content': system});
    }
    messages.add({'role': 'user', 'content': prompt});

    return {
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': streamingEnabled,
    };
  }
}

/// Google Gemini Pro API configuration
class GeminiProConfig extends CloudConfig {
  const GeminiProConfig({
    required String apiKey,
    String model = 'gemini-pro',
    String? baseUrl,
    int maxTokens = 2048,
    double temperature = 0.7,
    bool streamingEnabled = true,
  }) : super(
          provider: 'gemini',
          model: model,
          apiKey: apiKey,
          baseUrl: baseUrl,
          maxTokens: maxTokens,
          temperature: temperature,
          streamingEnabled: streamingEnabled,
        );

  @override
  String get endpoint =>
      '${baseUrl ?? 'https://generativelanguage.googleapis.com'}/v1/models/$model:streamGenerateContent';

  @override
  Map<String, String> toHeaders() => {'Content-Type': 'application/json'};

  @override
  Map<String, dynamic> toRequestBody(String prompt, String? system) {
    final contents = <Map<String, dynamic>>[];

    if (system != null) {
      contents.add({
        'parts': [
          {'text': system},
        ],
        'role': 'user',
      });
      contents.add({
        'parts': [
          {'text': 'Understood.'},
        ],
        'role': 'model',
      });
    }

    contents.add({
      'parts': [
        {'text': prompt},
      ],
      'role': 'user',
    });

    return {
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
      },
    };
  }
}
