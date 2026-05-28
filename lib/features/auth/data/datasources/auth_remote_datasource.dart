import 'dart:math' show min;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<User?> get firebaseAuthStateChanges;
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> signUpWithEmail(String email, String password, String username);
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<UserModel> getUserDocument(String uid);
  Future<void> deleteAccount();
  UserModel buildModelFromCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  @override
  Stream<User?> get firebaseAuthStateChanges => _auth.userChanges();

  @override
  UserModel buildModelFromCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(code: 'no-user', message: 'Not authenticated');
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      username: user.displayName ?? 'user_${user.uid.substring(0, 6)}',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      role: AppConstants.roleUser,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      try {
        return await _getUserOrThrow(user.uid);
      } catch (_) {
        return buildModelFromCurrentUser();
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<UserModel> signUpWithEmail(
      String email, String password, String username) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;

      final model = UserModel(
        uid: user.uid,
        email: email.trim(),
        username: username.trim(),
        displayName: username.trim(),
        role: AppConstants.roleUser,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(model.toCreateMap());

      await user.updateDisplayName(username.trim());

      return model;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException(
            code: 'cancelled', message: 'Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      try {
        return await _upsertSocialUser(userCredential.user!);
      } catch (_) {
        return buildModelFromCurrentUser();
      }
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut().catchError((_) => null),
    ]);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<UserModel> getUserDocument(String uid) => _getUserOrThrow(uid);

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete()
        .catchError((_) {});

    await _googleSignIn.signOut().catchError((_) => null);

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<UserModel> _getUserOrThrow(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) throw const NotFoundException(message: 'User not found');
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> _upsertSocialUser(User firebaseUser) async {
    final ref = _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid);

    final doc = await ref.get();
    if (!doc.exists) {
      final username = _sanitizeUsername(
          firebaseUser.displayName ?? firebaseUser.email ?? 'user');
      final model = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        username: username,
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        role: AppConstants.roleUser,
        createdAt: DateTime.now(),
      );
      await ref.set(model.toCreateMap());
      return model;
    }

    await ref.update({
      'displayName': firebaseUser.displayName,
      'photoUrl': firebaseUser.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return UserModel.fromFirestore(await ref.get());
  }

  String _sanitizeUsername(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return cleaned.substring(0, min(30, cleaned.length));
  }

  AuthException _mapFirebaseError(FirebaseAuthException e) {
    AppLogger.warning('FirebaseAuth error: ${e.code}', e);
    return AuthException(code: e.code, message: _errorMessage(e.code));
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'requires-recent-login':
        return 'requires-recent-login';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
