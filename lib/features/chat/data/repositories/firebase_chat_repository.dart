import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

/// Firestore-backed chat repository.
///
/// Conversation ID = sorted([uid1, uid2]).join('_')  — deterministic,
/// so both sides always read/write to the same document.
///
/// Structure:
///   conversations/{convId}
///     participants: [uid1, uid2]
///     participantNames: {uid1: name, uid2: name}
///     lastMessage: string
///     lastTime: Timestamp
///     unread_{uid}: int   (per-participant unread counter)
///
///   conversations/{convId}/messages/{msgId}
///     senderId, senderName, text, timestamp (serverTimestamp), isRead
class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _db;
  static const _uuid = Uuid();

  FirebaseChatRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  String _convId(String uid1, String uid2) {
    final s = [uid1, uid2]..sort();
    return '${s[0]}_${s[1]}';
  }

  @override
  Stream<List<ChatMessage>> messagesStream(String uid1, String uid2) {
    final convId = _convId(uid1, uid2);
    return _db
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _msgFromDoc(d, convId)).toList());
  }

  @override
  Stream<List<ChatConversation>> conversationsStream(String uid) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _convFromDoc(d, uid))
            .whereType<ChatConversation>()
            .toList());
  }

  @override
  Future<void> sendMessage({
    required String fromId,
    required String fromName,
    required String toId,
    required String toName,
    required String text,
  }) async {
    final convId = _convId(fromId, toId);
    final convRef = _db.collection('conversations').doc(convId);
    final msgId = _uuid.v4();

    final batch = _db.batch();

    // Upsert conversation metadata
    batch.set(
      convRef,
      {
        'participants': [fromId, toId],
        'participantNames': {fromId: fromName, toId: toName},
        'lastMessage': text,
        'lastTime': FieldValue.serverTimestamp(),
        // Increment unread for the recipient
        'unread_$toId': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    // Write the message
    batch.set(
      convRef.collection('messages').doc(msgId),
      {
        'id': msgId,
        'senderId': fromId,
        'senderName': fromName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      },
    );

    await batch.commit();
  }

  @override
  Future<void> markRead(String uid, String otherUid) async {
    final convId = _convId(uid, otherUid);
    final convRef = _db.collection('conversations').doc(convId);

    // Reset unread counter for this user
    await convRef.set({'unread_$uid': 0}, SetOptions(merge: true));

    // Mark all unread messages from the other user as read
    final unread = await convRef
        .collection('messages')
        .where('senderId', isEqualTo: otherUid)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────

  ChatMessage _msgFromDoc(DocumentSnapshot doc, String convId) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      conversationId: convId,
      senderId: d['senderId'] as String? ?? '',
      senderName: d['senderName'] as String? ?? '',
      text: d['text'] as String? ?? '',
      time: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] as bool? ?? false,
    );
  }

  ChatConversation? _convFromDoc(DocumentSnapshot doc, String myUid) {
    final d = doc.data() as Map<String, dynamic>?;
    if (d == null) return null;

    final participants = List<String>.from(d['participants'] as List? ?? []);
    final otherUid = participants.firstWhere(
      (p) => p != myUid,
      orElse: () => '',
    );
    if (otherUid.isEmpty) return null;

    final names = d['participantNames'] as Map<String, dynamic>? ?? {};
    final otherName = names[otherUid] as String? ?? otherUid;
    final unread = (d['unread_$myUid'] as num?)?.toInt() ?? 0;
    final lastTime =
        (d['lastTime'] as Timestamp?)?.toDate() ?? DateTime.now();

    return ChatConversation(
      id: doc.id,
      otherUserId: otherUid,
      otherUserName: otherName,
      lastMessage: d['lastMessage'] as String? ?? '',
      lastTime: lastTime,
      unread: unread,
    );
  }
}
