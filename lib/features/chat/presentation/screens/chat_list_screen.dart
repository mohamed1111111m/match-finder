import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold();

    final conversationsAsync =
        ref.watch(chatConversationsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('الرسائل')),
      body: conversationsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 64, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('مفيش محادثات لسه',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('تقدر تبدأ محادثة من صفحة أي فريق',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (ctx, i) {
              final conv = conversations[i];
              final unread = conv.unread;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    conv.otherUserName.isNotEmpty
                        ? conv.otherUserName[0]
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18),
                  ),
                ),
                title: Text(conv.otherUserName,
                    style: TextStyle(
                        fontWeight: unread > 0
                            ? FontWeight.w800
                            : FontWeight.w700,
                        fontSize: 14)),
                subtitle: conv.lastMessage.isEmpty
                    ? null
                    : Text(conv.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: unread > 0
                                ? Theme.of(context).colorScheme.onSurface
                                : AppColors.textMuted)),
                trailing: unread > 0
                    ? Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle),
                        child: Center(
                          child: Text('$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      )
                    : Text(_timeLabel(conv.lastTime),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                onTap: () => context.push(
                    '/chat/${conv.otherUserId}'
                    '?name=${Uri.encodeComponent(conv.otherUserName)}'),
              );
            },
          );
        },
      ),
    );
  }

  String _timeLabel(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return '${diff.inMinutes}د';
    if (diff.inDays < 1) return '${diff.inHours}س';
    return '${t.day}/${t.month}';
  }
}
