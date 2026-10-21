import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:watch_your_money/domain/models/noir_settings_model.dart';

class OllamaClient {
  final NoirSettingsModel settings;
  late final http.Client _client;
  final String _baseUrl;

  OllamaClient(this.settings) : _baseUrl = settings.ollamaHost.replaceAll(RegExp(r'/$'), '') {
    _client = http.Client();
  }

  // Health check
  Future<bool> isHealthy() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/tags'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // List available models
  Future<List<String>> listModels() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/tags'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['models'] as List).map((m) => m['name'] as String).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Check if specific model is available
  Future<bool> hasModel(String modelName) async {
    final models = await listModels();
    return models.any((m) => m == modelName || m.startsWith('$modelName:'));
  }

  // Pull/download a model
  Future<bool> pullModel(String modelName, {void Function(double progress)? onProgress}) async {
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/api/pull'));
      request.body = json.encode({'name': modelName});
      request.headers['Content-Type'] = 'application/json';

      final streamedResponse = await _client.send(request).timeout(const Duration(minutes: 10));

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final data = json.decode(line);
            if (data['status'] == 'downloading' && onProgress != null && data['completed'] != null && data['total'] != null) {
              onProgress((data['completed'] as num) / (data['total'] as num));
            }
          } catch (_) {}
        }
      }
      return streamedResponse.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Non-streaming chat completion
  Future<OllamaChatResponse> chat({
    required List<OllamaMessage> messages,
    double? temperature,
    int? maxTokens,
    List<OllamaTool>? tools,
  }) async {
    final requestBody = {
      'model': settings.modelName,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': false,
      'options': {
        'temperature': temperature ?? settings.temperature,
        'num_predict': maxTokens ?? settings.maxTokens,
      },
    };

    if (tools != null && tools.isNotEmpty) {
      requestBody['tools'] = tools.map((t) => t.toJson()).toList();
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: settings.maxTokens ~/ 10 + 30)); // Dynamic timeout

      if (response.statusCode == 200) {
        return OllamaChatResponse.fromJson(json.decode(response.body));
      } else {
        throw OllamaException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw OllamaException('Chat request failed: $e');
    }
  }

  // Streaming chat completion
  Stream<OllamaChatChunk> chatStream({
    required List<OllamaMessage> messages,
    double? temperature,
    int? maxTokens,
    List<OllamaTool>? tools,
  }) async* {
    final requestBody = {
      'model': settings.modelName,
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': true,
      'options': {
        'temperature': temperature ?? settings.temperature,
        'num_predict': maxTokens ?? settings.maxTokens,
      },
    };

    if (tools != null && tools.isNotEmpty) {
      requestBody['tools'] = tools.map((t) => t.toJson()).toList();
    }

    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/api/chat'))
        ..headers['Content-Type'] = 'application/json'
        ..body = json.encode(requestBody);

      final streamedResponse = await _client.send(request).timeout(
        Duration(seconds: settings.maxTokens ~/ 10 + 60),
      );

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final data = json.decode(line);
            yield OllamaChatChunk.fromJson(data);
            if (data['done'] == true) return;
          } catch (_) {}
        }
      }
    } catch (e) {
      throw OllamaException('Stream request failed: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

class OllamaMessage {
  final String role; // 'system' | 'user' | 'assistant' | 'tool'
  final String content;
  final List<OllamaToolCall>? toolCalls;
  final String? toolCallId;

  OllamaMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolCallId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'role': role, 'content': content};
    if (toolCalls != null && toolCalls!.isNotEmpty) {
      map['tool_calls'] = toolCalls!.map((tc) => tc.toJson()).toList();
    }
    if (toolCallId != null) {
      map['tool_call_id'] = toolCallId;
    }
    return map;
  }

  static OllamaMessage fromJson(Map<String, dynamic> json) => OllamaMessage(
        role: json['role'] as String,
        content: json['content'] as String? ?? '',
        toolCalls: (json['tool_calls'] as List?)?.map((e) => OllamaToolCall.fromJson(e)).toList(),
        toolCallId: json['tool_call_id'] as String?,
      );
}

class OllamaToolCall {
  final String id;
  final String type; // 'function'
  final OllamaFunction function;

  OllamaToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'function': function.toJson(),
      };

  static OllamaToolCall fromJson(Map<String, dynamic> json) => OllamaToolCall(
        id: json['id'] as String,
        type: json['type'] as String,
        function: OllamaFunction.fromJson(json['function'] as Map<String, dynamic>),
      );
}

class OllamaFunction {
  final String name;
  final Map<String, dynamic> arguments;

  OllamaFunction({
    required this.name,
    required this.arguments,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'arguments': arguments,
      };

  static OllamaFunction fromJson(Map<String, dynamic> json) => OllamaFunction(
        name: json['name'] as String,
        arguments: Map<String, dynamic>.from(json['arguments'] as Map),
      );
}

class OllamaTool {
  final String type; // 'function'
  final OllamaToolFunction function;

  OllamaTool({
    required this.type,
    required this.function,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'function': function.toJson(),
      };
}

class OllamaToolFunction {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  OllamaToolFunction({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': parameters,
      };
}

class OllamaChatResponse {
  final String model;
  final DateTime createdAt;
  final OllamaMessage message;
  final bool done;
  final int? totalDuration;
  final int? loadDuration;
  final int? promptEvalCount;
  final int? promptEvalDuration;
  final int? evalCount;
  final int? evalDuration;

  OllamaChatResponse({
    required this.model,
    required this.createdAt,
    required this.message,
    required this.done,
    this.totalDuration,
    this.loadDuration,
    this.promptEvalCount,
    this.promptEvalDuration,
    this.evalCount,
    this.evalDuration,
  });

  factory OllamaChatResponse.fromJson(Map<String, dynamic> json) => OllamaChatResponse(
        model: json['model'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        message: OllamaMessage.fromJson(json['message'] as Map<String, dynamic>),
        done: json['done'] as bool,
        totalDuration: json['total_duration'] as int?,
        loadDuration: json['load_duration'] as int?,
        promptEvalCount: json['prompt_eval_count'] as int?,
        promptEvalDuration: json['prompt_eval_duration'] as int?,
        evalCount: json['eval_count'] as int?,
        evalDuration: json['eval_duration'] as int?,
      );
}

class OllamaChatChunk {
  final String model;
  final DateTime createdAt;
  final OllamaMessage? message;
  final bool done;
  final int? totalDuration;
  final int? loadDuration;
  final int? promptEvalCount;
  final int? promptEvalDuration;
  final int? evalCount;
  final int? evalDuration;

  OllamaChatChunk({
    required this.model,
    required this.createdAt,
    this.message,
    required this.done,
    this.totalDuration,
    this.loadDuration,
    this.promptEvalCount,
    this.promptEvalDuration,
    this.evalCount,
    this.evalDuration,
  });

  factory OllamaChatChunk.fromJson(Map<String, dynamic> json) => OllamaChatChunk(
        model: json['model'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        message: json['message'] != null ? OllamaMessage.fromJson(json['message'] as Map<String, dynamic>) : null,
        done: json['done'] as bool,
        totalDuration: json['total_duration'] as int?,
        loadDuration: json['load_duration'] as int?,
        promptEvalCount: json['prompt_eval_count'] as int?,
        promptEvalDuration: json['prompt_eval_duration'] as int?,
        evalCount: json['eval_count'] as int?,
        evalDuration: json['eval_duration'] as int?,
      );
}

class OllamaException implements Exception {
  final String message;
  OllamaException(this.message);
  @override
  String toString() => 'OllamaException: $message';
}