import 'package:hive/hive.dart';
import 'package:watch_your_money/domain/models/chat_message_model.dart';
import 'package:watch_your_money/domain/repositories/chat_message_repository.dart';

class HiveChatMessageRepository implements ChatMessageRepository {
  static const String _boxName = 'chat_messages';
  late Box<ChatMessageModel> _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<ChatMessageModel>(_boxName);
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String sessionId) async {
    final messages = _box.values
        .where((m) => m.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  @override
  Future<void> addMessage(ChatMessageModel message) async {
    await _box.put(message.id, message);
  }

  @override
  Future<void> updateMessage(ChatMessageModel message) async {
    await _box.put(message.id, message);
  }

  @override
  Future<void> deleteMessages(String sessionId) async {
    final keysToDelete = _box.values
        .where((m) => m.sessionId == sessionId)
        .map((m) => m.key)
        .toList();
    await _box.deleteAll(keysToDelete);
  }

  @override
  Future<void> deleteAllMessages() async {
    await _box.clear();
  }

  @override
  Future<String?> getLatestSessionId() async {
    if (_box.isEmpty) return null;
    final messages = _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages.first.sessionId;
  }
}