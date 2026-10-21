import 'package:watch_your_money/domain/models/chat_message_model.dart';

abstract class ChatMessageRepository {
  Future<void> init();
  Future<List<ChatMessageModel>> getMessages(String sessionId);
  Future<void> addMessage(ChatMessageModel message);
  Future<void> updateMessage(ChatMessageModel message);
  Future<void> deleteMessages(String sessionId);
  Future<void> deleteAllMessages();
  Future<String?> getLatestSessionId();
}