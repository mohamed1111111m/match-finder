import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../support/presentation/providers/support_provider.dart';

class AdminSupportScreen extends ConsumerWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(adminSupportChatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('رسائل الدعم')),
      body: chatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.support_agent_outlined,
                      size: 64, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('مفيش رسائل دعم',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 15)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) =>
                _ChatTile(chat: chats[i], index: i),
          );
        },
      ),
    );
  }
}

// ── Chat list tile ─────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final SupportChat chat;
  final int index;
  const _ChatTile({required this.chat, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AdminSupportChatScreen(chat: chat),
      )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: chat.hasUnread
                ? AppColors.primary.withValues(alpha: 0.6)
                : cs.outline,
            width: chat.hasUnread ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                chat.userName.isNotEmpty ? chat.userName[0] : '?',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat.userName,
                      style: TextStyle(
                          fontWeight: chat.hasUnread
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          color: chat.hasUnread
                              ? cs.onSurface
                              : AppColors.textMuted)),
                ],
              ),
            ),
            if (chat.hasUnread)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.04),
    );
  }
}

// ── Admin chat detail ──────────────────────────────────────────────────────────

class AdminSupportChatScreen extends ConsumerStatefulWidget {
  final SupportChat chat;
  const AdminSupportChatScreen({super.key, required this.chat});

  @override
  ConsumerState<AdminSupportChatScreen> createState() =>
      _AdminSupportChatScreenState();
}

class _AdminSupportChatScreenState
    extends ConsumerState<AdminSupportChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ref
        .read(supportNotifierProvider.notifier)
        .markRead(widget.chat.userId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await ref.read(supportNotifierProvider.notifier).sendAdminReply(
      userId: widget.chat.userId,
      text: text,
    );
    _scrollToBottom();
  }

  String _fmt(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'ص' : 'م';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(adminSupportMessagesProvider(widget.chat.userId));
    final isSending = ref.watch(supportNotifierProvider);

    messagesAsync.whenData((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.userName),
        titleTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            fontFamily: 'Cairo',
            color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (messages) => ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: messages.length,
                itemBuilder: (ctx, i) {
                  final msg = messages[i];
                  return _AdminBubble(
                    text: msg.text,
                    isAdmin: msg.isFromAdmin,
                    timeLabel: _fmt(msg.createdAt),
                  ).animate().fadeIn(duration: 200.ms);
                },
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.outline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'رد على المستخدم...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isSending ? null : _send,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: isSending
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBubble extends StatelessWidget {
  final String text;
  final bool isAdmin;
  final String timeLabel;
  const _AdminBubble(
      {required this.text, required this.isAdmin, required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAdmin ? AppColors.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isAdmin ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isAdmin ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: isAdmin ? null : Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isAdmin ? Colors.white : cs.onSurface)),
            const SizedBox(height: 4),
            Text(timeLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: isAdmin
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
