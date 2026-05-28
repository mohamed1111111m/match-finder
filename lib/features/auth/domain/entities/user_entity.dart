import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String username;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? bio;
  final String role; // 'user' | 'admin' | 'support'
  final String? fcmToken;
  final int wins;
  final int losses;
  final int totalMatches;
  final int points;
  final int globalRank;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.username,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.bio,
    required this.role,
    this.fcmToken,
    this.wins = 0,
    this.losses = 0,
    this.totalMatches = 0,
    this.points = 0,
    this.globalRank = 0,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isSupport => role == 'support';

  double get winRate =>
      totalMatches == 0 ? 0 : (wins / totalMatches) * 100;

  UserEntity copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? role,
    String? fcmToken,
    int? wins,
    int? losses,
    int? totalMatches,
    int? points,
    int? globalRank,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      totalMatches: totalMatches ?? this.totalMatches,
      points: points ?? this.points,
      globalRank: globalRank ?? this.globalRank,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [uid, email, username, role, wins, losses, points];
}
