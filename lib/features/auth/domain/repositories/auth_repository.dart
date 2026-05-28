import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Returns a stream of the currently authenticated user (null = signed out).
  Stream<UserEntity?> get authStateChanges;

  /// Email + password sign-in.
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Email + password registration — also creates Firestore user document.
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  });

  /// Google OAuth sign-in / sign-up.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Sign out from Firebase and all social providers.
  Future<Either<Failure, Unit>> signOut();

  /// Send password reset email.
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  /// Fetch the current user's profile from Firestore.
  Future<Either<Failure, UserEntity>> getCurrentUser(String uid);

  /// Permanently delete the current user's account and all associated data.
  Future<Either<Failure, Unit>> deleteAccount();
}
