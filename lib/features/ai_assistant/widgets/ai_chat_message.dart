// Chat message model for AI Assistant.

class AIChatMessage {
  final String text;
  final bool isAI;
  final bool isStreaming;
  final bool isWelcome;

  const AIChatMessage({
    required this.text,
    required this.isAI,
    this.isStreaming = false,
    this.isWelcome = false,
  });

  AIChatMessage copyWith({
    String? text,
    bool? isAI,
    bool? isStreaming,
    bool? isWelcome,
  }) {
    return AIChatMessage(
      text: text ?? this.text,
      isAI: isAI ?? this.isAI,
      isStreaming: isStreaming ?? this.isStreaming,
      isWelcome: isWelcome ?? this.isWelcome,
    );
  }
}