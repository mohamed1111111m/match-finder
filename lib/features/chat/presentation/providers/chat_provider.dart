import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../data/repositories/demo_chat_repository.dart';
import '../../data/repositories/firebase_chat_repository.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

// ── Repository provider ────────────────────────────────────────────────────────
// In demo mode this is overridden in main.dart with DemoChatRepository.

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (AppConfig.isDemoMode) return DemoChatRepository();
  return FirebaseChatRepository();
});

// ── Real-time messages stream (family: otherUserId) ───────────────────────────

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, ConvKey>((ref, key) {
  return ref
      .watch(chatRepositoryProvider)
      .messagesStream(key.myId, key.otherId);
});

// ── Real-time conversations stream ────────────────────────────────────────────

final chatConversationsProvider =
    StreamProvider.family<List<ChatConversation>, String>((ref, uid) {
  return ref.watch(chatRepositoryProvider).conversationsStream(uid);
});

// ── Send-message notifier ─────────────────────────────────────────────────────

class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repo;
  SendMessageNotifier(this._repo) : super(const AsyncData(null));

  Future<void> send({
    required String fromId,
    required String fromName,
    required String toId,
    required String toName,
    required String text,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.sendMessage(
        fromId: fromId,
        fromName: fromName,
        toId: toId,
        toName: toName,
        text: text,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final sendMessageProvider =
    StateNotifierProvider<SendMessageNotifier, AsyncValue<void>>((ref) {
  return SendMessageNotifier(ref.watch(chatRepositoryProvider));
});

// ── Mark-read helper ──────────────────────────────────────────────────────────

final markReadProvider = Provider.family<Future<void> Function(), ConvKey>(
  (ref, key) => () =>
      ref.read(chatRepositoryProvider).markRead(key.myId, key.otherId),
);

// ── Key type ──────────────────────────────────────────────────────────────────

class ConvKey {
  final String myId;
  final String otherId;
  const ConvKey(this.myId, this.otherId);

  @override
  bool operator ==(Object other) =>
      other is ConvKey && myId == other.myId && otherId == other.otherId;

  @override
  int get hashCode => Object.hash(myId, otherId);
}

/// Convenience constructor so call sites read naturally:
///   ref.watch(chatMessagesProvider(convKey(myId, otherId)))
ConvKey convKey(String myId, String otherId) => ConvKey(myId, otherId);
