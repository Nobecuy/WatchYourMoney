import 'package:hive/hive.dart';

part 'noir_settings_model.g.dart';

@HiveType(typeId: 14)
class NoirSettingsModel extends HiveObject {
  @HiveField(0)
  String modelName; // e.g., 'llama3.2:3b', 'llama3.1:8b', 'qwen2.5:7b'

  @HiveField(1)
  String ollamaHost; // e.g., 'http://localhost:11434', 'http://10.0.2.2:11434' (Android emulator)

  @HiveField(2)
  double temperature; // 0.0 - 1.0

  @HiveField(3)
  int maxTokens; // Max tokens for response

  @HiveField(4)
  bool enabled; // Whether AI assistant is enabled

  @HiveField(5)
  int maxToolCallsPerTurn; // Safety limit

  @HiveField(6)
  int contextTokenBudget; // Max tokens for context

  NoirSettingsModel({
    this.modelName = 'llama3.2:3b',
    this.ollamaHost = 'http://localhost:11434',
    this.temperature = 0.3,
    this.maxTokens = 2048,
    this.enabled = true,
    this.maxToolCallsPerTurn = 5,
    this.contextTokenBudget = 4000,
  });

  factory NoirSettingsModel.fromJson(Map<String, dynamic> json) => NoirSettingsModel(
        modelName: json['model_name'] as String? ?? 'llama3.2:3b',
        ollamaHost: json['ollama_host'] as String? ?? 'http://localhost:11434',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
        maxTokens: json['max_tokens'] as int? ?? 2048,
        enabled: json['enabled'] as bool? ?? true,
        maxToolCallsPerTurn: json['max_tool_calls_per_turn'] as int? ?? 5,
        contextTokenBudget: json['context_token_budget'] as int? ?? 4000,
      );

  Map<String, dynamic> toJson() => {
        'model_name': modelName,
        'ollama_host': ollamaHost,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'enabled': enabled,
        'max_tool_calls_per_turn': maxToolCallsPerTurn,
        'context_token_budget': contextTokenBudget,
      };

  NoirSettingsModel copyWith({
    String? modelName,
    String? ollamaHost,
    double? temperature,
    int? maxTokens,
    bool? enabled,
    int? maxToolCallsPerTurn,
    int? contextTokenBudget,
  }) =>
      NoirSettingsModel(
        modelName: modelName ?? this.modelName,
        ollamaHost: ollamaHost ?? this.ollamaHost,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        enabled: enabled ?? this.enabled,
        maxToolCallsPerTurn: maxToolCallsPerTurn ?? this.maxToolCallsPerTurn,
        contextTokenBudget: contextTokenBudget ?? this.contextTokenBudget,
      );

  // Predefined model recommendations
  static const List<String> recommendedModels = [
    'llama3.2:3b',    // ~2GB - Fast, good tool calling
    'llama3.1:8b',    // ~4.7GB - Better reasoning
    'qwen2.5:7b',     // ~4.4GB - Strong tool calling
    'nemotron3:8b',   // ~4.7GB - Strong tool calling
    'phi3:3.8b',      // ~2.3GB - Compact
  ];

  static const Map<String, String> modelDescriptions = {
    'llama3.2:3b': 'Llama 3.2 3B (~2GB) - Cepat, cocok untuk tool calling',
    'llama3.1:8b': 'Llama 3.1 8B (~4.7GB) - Reasoning lebih baik',
    'qwen2.5:7b': 'Qwen 2.5 7B (~4.4GB) - Tool calling kuat',
    'nemotron3:8b': 'Nemotron 3 8B (~4.7GB) - Tool calling kuat',
    'phi3:3.8b': 'Phi-3 3.8B (~2.3GB) - Ringkas & efisien',
  };
}