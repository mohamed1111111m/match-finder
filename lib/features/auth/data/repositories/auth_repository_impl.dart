import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _networkInfo = networkInfo;

  static const _ownerEmail = 'maco544look@gmail.com';

  @override
  Stream<UserEntity?> get authStateChanges async* {
    yield* _remote.firebaseAuthStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final user = await _remote.getUserDocument(firebaseUser.uid);
        if (firebaseUser.email == _ownerEmail && !user.isAdmin) {
          return user.copyWith(role: 'admin');
        }
        return user;
      } catch (e) {
        AppLogger.warning('Firestore user doc unavailable, using auth fallback', e);
        try {
          return _remote.buildModelFromCurrentUser();
        } catch (_) {
          return null;
        }
      }
    });
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _execute(() => _remote.signInWithEmail(email, password));

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) =>
      _execute(() => _remote.signUpWithEmail(email, password, username));

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() =>
      _execute(() => _remote.signInWithGoogle());

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remote.signOut();
      return const Right(unit);
    } catch (e) {
      AppLogger.error('SignOut failed', e);
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.sendPasswordResetEmail(email);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser(String uid) =>
      _execute(() => _remote.getUserDocument(uid));

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    try {
      await _remote.deleteAccount();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      AppLogger.error('Delete account failed', e);
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ─── Private helper ────────────────────────────────────────────────────────

  Future<Either<Failure, UserModel>> _execute(
      Future<UserModel> Function() fn) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await fn();
      return Right(result);
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on NotFoundException {
      return const Left(UserNotFoundFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Auth repository error', e);
      return Left(UnknownFailure(e.toString()));
    }
  }

  Failure _mapAuthException(AuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const UserNotFoundFailure();
      case 'wrong-password':
      case 'invalid-credential':
        return const WrongPasswordFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'too-many-requests':
        return const TooManyRequestsFailure();
      case 'cancelled':
        return const AuthFailure('Sign-in was cancelled.');
      case 'requires-recent-login':
        return const RecentLoginRequiredFailure();
      default:
        return AuthFailure(e.message);
    }
  }
}
