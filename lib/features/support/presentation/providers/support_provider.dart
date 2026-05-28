import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class SupportMessage {
  final String id;
  final String text;
  final bool isFromAdmin;
  final DateTime createdAt;
  const SupportMessage({
    required this.id,
    required this.text,
    required this.isFromAdmin,
    required this.createdAt,
  });

  factory SupportMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return SupportMessage(
      id: doc.id,
      text: d['text'] as String? ?? '',
      isFromAdmin: d['isFromAdmin'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class SupportChat {
  final String userId;
  final String userName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool hasUnread;
  const SupportChat({
    required this.userId,
    required this.userName,
    required this.lastMessage,
    required this.lastMessageAt,
    this.hasUnread = false,
  });

  factory SupportChat.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return SupportChat(
      userId: doc.id,
      userName: d['userName'] as String? ?? 'مستخدم',
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasUnread: d['adminUnread'] as bool? ?? false,
    );
  }
}

// ── User-side: stream own messages ────────────────────────────────────────────

final userSupportMessagesProvider =
    StreamProvider.family<List<SupportMessage>, String>(
  (ref, userId) => FirebaseFirestore.instance
      .collection(AppConstants.supportChatsCollection)
      .doc(userId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(SupportMessage.fromFirestore).toList()),
);

// ── Admin-side: list all open chats ───────────────────────────────────────────

final adminSupportChatsProvider =
    StreamProvider<List<SupportChat>>(
  (ref) => FirebaseFirestore.instance
      .collection(AppConstants.supportChatsCollection)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SupportChat.fromFirestore).toList()),
);

// ── Admin-side: stream one user's messages ────────────────────────────────────

final adminSupportMessagesProvider =
    StreamProvider.family<List<SupportMessage>, String>(
  (ref, userId) => FirebaseFirestore.instance
      .collection(AppConstants.supportChatsCollection)
      .doc(userId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(SupportMessage.fromFirestore).toList()),
);

// ── Actions ───────────────────────────────────────────────────────────────────

class SupportNotifier extends StateNotifier<bool> {
  SupportNotifier() : super(false);

  final _db = FirebaseFirestore.instance;

  Future<void> sendUserMessage({
    required String userId,
    required String userName,
    required String text,
  }) async {
    state = true;
    try {
      final chatRef = _db
          .collection(AppConstants.supportChatsCollection)
          .doc(userId);

      final msg = {
        'text': text,
        'isFromAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = _db.batch();
      batch.set(chatRef, {
        'userId': userId,
        'userName': userName,
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'adminUnread': true,
      }, SetOptions(merge: true));
      batch.set(chatRef.collection('messages').doc(), msg);
      await batch.commit();
    } finally {
      state = false;
    }
  }

  Future<void> sendAdminReply({
    required String userId,
    required String text,
  }) async {
    state = true;
    try {
      final chatRef = _db
          .collection(AppConstants.supportChatsCollection)
          .doc(userId);

      final msg = {
        'text': text,
        'isFromAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = _db.batch();
      batch.update(chatRef, {
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'adminUnread': false,
      });
      batch.set(chatRef.collection('messages').doc(), msg);
      await batch.commit();
    } finally {
      state = false;
    }
  }

  Future<void> markRead(String userId) async {
    await _db
        .collection(AppConstants.supportChatsCollection)
        .doc(userId)
        .update({'adminUnread': false});
  }
}

final supportNotifierProvider =
    StateNotifierProvider<SupportNotifier, bool>(
  (_) => SupportNotifier(),
);
