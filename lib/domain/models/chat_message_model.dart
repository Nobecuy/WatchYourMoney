import 'package:hive/hive.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 10)
class ChatMessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String role; // 'user' | 'assistant' | 'tool'

  @HiveField(2)
  final String content;

  @HiveField(3)
  final List<ToolCall>? toolCalls;

  @HiveField(4)
  final List<ToolResult>? toolResults;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String sessionId;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolResults,
    required this.timestamp,
    required this.sessionId,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        toolCalls: (json['tool_calls'] as List?)?.map((e) => ToolCall.fromJson(e)).toList(),
        toolResults: (json['tool_results'] as List?)?.map((e) => ToolResult.fromJson(e)).toList(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        sessionId: json['session_id'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'tool_calls': toolCalls?.map((e) => e.toJson()).toList(),
        'tool_results': toolResults?.map((e) => e.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
        'session_id': sessionId,
      };

  ChatMessageModel copyWith({
    String? id,
    String? role,
    String? content,
    List<ToolCall>? toolCalls,
    List<ToolResult>? toolResults,
    DateTime? timestamp,
    String? sessionId,
  }) =>
      ChatMessageModel(
        id: id ?? this.id,
        role: role ?? this.role,
        content: content ?? this.content,
        toolCalls: toolCalls ?? this.toolCalls,
        toolResults: toolResults ?? this.toolResults,
        timestamp: timestamp ?? this.timestamp,
        sessionId: sessionId ?? this.sessionId,
      );
}

@HiveType(typeId: 11)
class ToolCall {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final Map<String, dynamic> arguments;

  ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) => ToolCall(
        id: json['id'] as String,
        name: json['name'] as String,
        arguments: Map<String, dynamic>.from(json['arguments'] as Map),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'arguments': arguments,
      };
}

@HiveType(typeId: 12)
class ToolResult {
  @HiveField(0)
  final String toolCallId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final bool isError;

  ToolResult({
    required this.toolCallId,
    required this.name,
    required this.content,
    this.isError = false,
  });

  factory ToolResult.fromJson(Map<String, dynamic> json) => ToolResult(
        toolCallId: json['tool_call_id'] as String,
        name: json['name'] as String,
        content: json['content'] as String,
        isError: json['is_error'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'tool_call_id': toolCallId,
        'name': name,
        'content': content,
        'is_error': isError,
      };
}