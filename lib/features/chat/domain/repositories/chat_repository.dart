import '../entities/chat_message_entity.dart';

abstract class ChatRepository {
  /// Real-time stream of messages for a conversation between two users.
  Stream<List<ChatMessage>> messagesStream(String uid1, String uid2);

  /// Real-time stream of all conversations the given user participates in.
  Stream<List<ChatConversation>> conversationsStream(String uid);

  /// Send a message (persists to backend).
  Future<void> sendMessage({
    required String fromId,
    required String fromName,
    required String toId,
    required String toName,
    required String text,
  });

  /// Mark all messages in a conversation as read by [uid].
  Future<void> markRead(String uid, String otherUid);
}
