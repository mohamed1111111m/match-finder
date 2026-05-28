import 'package:equatable/equatable.dart';

class ChatConversation extends Equatable {
  final String id; // sorted uid1_uid2
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastTime;
  final int unread;

  const ChatConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastTime,
    this.unread = 0,
  });

  @override
  List<Object?> get props => [id];
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime time;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.time,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [id];
}
