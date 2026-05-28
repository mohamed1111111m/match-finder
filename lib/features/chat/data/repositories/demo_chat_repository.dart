import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

/// In-memory chat repository for demo/offline mode.
/// Data is lost when the app restarts — acceptable in demo mode.
class DemoChatRepository implements ChatRepository {
  static const _uuid = Uuid();

  // convId → messages
  final Map<String, List<ChatMessage>> _messages = {};
  // convId → conversation
  final Map<String, ChatConversation> _conversations = {};

  // Controllers so we can push updates to existing stream subscribers
  final Map<String, StreamController<List<ChatMessage>>> _msgControllers = {};
  final Map<String, StreamController<List<ChatConversation>>> _convControllers = {};

  String _convId(String uid1, String uid2) {
    final s = [uid1, uid2]..sort();
    return '${s[0]}_${s[1]}';
  }

  @override
  Stream<List<ChatMessage>> messagesStream(String uid1, String uid2) {
    final cid = _convId(uid1, uid2);
    _msgControllers.putIfAbsent(
        cid, () => StreamController<List<ChatMessage>>.broadcast());
    // Emit current state immediately
    final ctrl = _msgControllers[cid]!;
    Future.microtask(() => ctrl.add(List.from(_messages[cid] ?? [])));
    return ctrl.stream;
  }

  @override
  Stream<List<ChatConversation>> conversationsStream(String uid) {
    _convControllers.putIfAbsent(
        uid, () => StreamController<List<ChatConversation>>.broadcast());
    final ctrl = _convControllers[uid]!;
    Future.microtask(() => ctrl.add(_convsForUser(uid)));
    return ctrl.stream;
  }

  @override
  Future<void> sendMessage({
    required String fromId,
    required String fromName,
    required String toId,
    required String toName,
    required String text,
  }) async {
    final cid = _convId(fromId, toId);
    final msg = ChatMessage(
      id: _uuid.v4(),
      conversationId: cid,
      senderId: fromId,
      senderName: fromName,
      text: text,
      time: DateTime.now(),
    );

    _messages[cid] = List.from(_messages[cid] ?? [])..add(msg);

    // Upsert conversation for both participants
    final conv = ChatConversation(
      id: cid,
      otherUserId: toId,
      otherUserName: toName,
      lastMessage: text,
      lastTime: DateTime.now(),
      unread: 0,
    );
    _conversations[cid] = conv;

    // Notify message subscribers
    _msgControllers[cid]?.add(List.from(_messages[cid]!));

    // Notify conversation subscribers for both users
    _convControllers[fromId]?.add(_convsForUser(fromId));
    _convControllers[toId]?.add(_convsForUser(toId));
  }

  @override
  Future<void> markRead(String uid, String otherUid) async {
    final cid = _convId(uid, otherUid);
    final msgs = _messages[cid];
    if (msgs == null) return;

    _messages[cid] = msgs
        .map((m) => m.senderId != uid
            ? ChatMessage(
                id: m.id,
                conversationId: m.conversationId,
                senderId: m.senderId,
                senderName: m.senderName,
                text: m.text,
                time: m.time,
                isRead: true,
              )
            : m)
        .toList();

    _msgControllers[cid]?.add(List.from(_messages[cid]!));
    _convControllers[uid]?.add(_convsForUser(uid));
  }

  List<ChatConversation> _convsForUser(String uid) {
    return _conversations.values
        .where((c) {
          final parts = c.id.split('_');
          return parts.contains(uid);
        })
        .toList()
      ..sort((a, b) => b.lastTime.compareTo(a.lastTime));
  }
}
