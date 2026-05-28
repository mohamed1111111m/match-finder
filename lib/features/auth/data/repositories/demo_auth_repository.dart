import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/mock/mock_data.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Fully offline auth repository used in demo mode.
/// All data is persisted via SharedPreferences.
class DemoAuthRepository implements AuthRepository {
  final _uuid = const Uuid();
  final _authController = StreamController<UserEntity?>.broadcast();

  // Bump this version to force re-seeding when defaults change.
  static const _seedVersion = '4';

  DemoAuthRepository() {
    _seedDemoUsers();
    _emitCurrent();
  }

  Future<void> _seedDemoUsers() async {
    final prefs = await SharedPreferences.getInstance();

    // Force re-seed when seed version changes so role updates take effect.
    if (prefs.getString('demo_seed_version') != _seedVersion) {
      await prefs.remove('demo_user_${AppConfig.demoUserEmail}');
      await prefs.remove('demo_user_${AppConfig.demoAdminEmail}');
      await prefs.setString('demo_seed_version', _seedVersion);
    }

    if (!prefs.containsKey('demo_user_${AppConfig.demoUserEmail}')) {
      await prefs.setString(
        'demo_user_${AppConfig.demoUserEmail}',
        jsonEncode({
          'uid': MockData.demoUser.uid,
          'email': MockData.demoUser.email,
          'username': MockData.demoUser.username,
          'password': AppConfig.demoUserPassword,
          'role': 'admin',
          'wins': MockData.demoUser.wins,
          'losses': MockData.demoUser.losses,
          'totalMatches': MockData.demoUser.totalMatches,
          'points': MockData.demoUser.points,
          'globalRank': MockData.demoUser.globalRank,
          'bio': MockData.demoUser.bio,
        }),
      );
    }

    if (!prefs.containsKey('demo_user_${AppConfig.demoAdminEmail}')) {
      await prefs.setString(
        'demo_user_${AppConfig.demoAdminEmail}',
        jsonEncode({
          'uid': MockData.demoAdmin.uid,
          'email': MockData.demoAdmin.email,
          'username': MockData.demoAdmin.username,
          'password': AppConfig.demoAdminPassword,
          'role': 'admin',
          'wins': 0,
          'losses': 0,
          'totalMatches': 0,
          'points': 9999,
          'globalRank': 1,
        }),
      );
    }
  }

  Future<void> _emitCurrent() async {
    final current = await _loadCurrentUser();
    _authController.add(current);
  }

  Future<UserEntity?> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('demo_current_user');
    if (email == null) return null;
    final raw = prefs.getString('demo_user_$email');
    if (raw == null) return null;
    return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  UserEntity _fromJson(Map<String, dynamic> d) {
    return UserEntity(
      uid: d['uid'] as String,
      email: d['email'] as String,
      username: d['username'] as String,
      displayName: d['displayName'] as String?,
      photoUrl: d['photoUrl'] as String?,
      bio: d['bio'] as String?,
      phoneNumber: d['phoneNumber'] as String?,
      role: d['role'] as String? ?? 'user',
      wins: (d['wins'] as num?)?.toInt() ?? 0,
      losses: (d['losses'] as num?)?.toInt() ?? 0,
      totalMatches: (d['totalMatches'] as num?)?.toInt() ?? 0,
      points: (d['points'] as num?)?.toInt() ?? 0,
      globalRank: (d['globalRank'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<UserEntity?> get authStateChanges => _authController.stream;

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final prefs = await SharedPreferences.getInstance();
    final key = 'demo_user_${email.trim().toLowerCase()}';
    final raw = prefs.getString(key);
    if (raw == null) return const Left(UserNotFoundFailure());

    final d = jsonDecode(raw) as Map<String, dynamic>;
    if (d['password'] != password) return const Left(WrongPasswordFailure());

    await prefs.setString('demo_current_user', email.trim().toLowerCase());
    final user = _fromJson(d);
    _authController.add(user);
    return Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final prefs = await SharedPreferences.getInstance();
    final key = 'demo_user_${email.trim().toLowerCase()}';
    if (prefs.containsKey(key)) return const Left(EmailAlreadyInUseFailure());

    final uid = _uuid.v4();
    final data = <String, dynamic>{
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'username': username.trim(),
      'password': password,
      'role': 'user',
      'wins': 0,
      'losses': 0,
      'totalMatches': 0,
      'points': 0,
      'globalRank': 0,
    };
    await prefs.setString(key, jsonEncode(data));
    await prefs.setString('demo_current_user', email.trim().toLowerCase());

    final user = _fromJson(data);
    _authController.add(user);
    return Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async =>
      signInWithEmail(
        email: AppConfig.demoUserEmail,
        password: AppConfig.demoUserPassword,
      );

  @override
  Future<Either<Failure, Unit>> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('demo_current_user');
    _authController.add(null);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser(String uid) async {
    final user = await _loadCurrentUser();
    if (user == null) return const Left(UserNotFoundFailure());
    return Right(user);
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('demo_current_user');
    if (email != null) {
      await prefs.remove('demo_user_$email');
      await prefs.remove('demo_current_user');
    }
    _authController.add(null);
    return const Right(unit);
  }
}
