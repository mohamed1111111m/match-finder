import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart'; // currentUserProvider

// ─── Profile update notifier ───────────────────────────────────────────────

class ProfileState {
  final bool isLoading;
  final bool isUploadingAvatar;
  final String? error;
  final bool success;
  const ProfileState({
    this.isLoading = false,
    this.isUploadingAvatar = false,
    this.error,
    this.success = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isUploadingAvatar,
    String? error,
    bool? success,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      error: error,
      success: success ?? this.success,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;

  // Lazy getter — only accessed when Firebase is available.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  ProfileNotifier(this._ref) : super(const ProfileState());

  Future<bool> updateProfile({
    required String userId,
    String? username,
    String? bio,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true);

    if (AppConfig.isDemoMode) {
      // In demo mode, simulate a successful update with a short delay.
      await Future.delayed(const Duration(milliseconds: 400));
      state = state.copyWith(isLoading: false, success: true);
      return true;
    }

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (username != null) updates['username'] = username.trim();
      if (bio != null) updates['bio'] = bio.trim();
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber.trim();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updates);

      state = state.copyWith(isLoading: false, success: true);
      return true;
    } catch (e) {
      AppLogger.error('updateProfile failed', e);
      state = state.copyWith(
          isLoading: false, error: 'Failed to update profile: $e');
      return false;
    }
  }

  Future<bool> uploadAvatar(String userId) async {
    state = state.copyWith(isUploadingAvatar: true);

    if (AppConfig.isDemoMode) {
      // Pick the image (so the user sees the picker) but skip upload.
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(isUploadingAvatar: false, success: true);
      return true;
    }

    try {
      final storageService = _ref.read(storageServiceProvider);
      final url = await storageService.pickAndUploadAvatar(userId);

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update Firebase Auth profile so userChanges() fires and
      // currentUserProvider refreshes automatically.
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);

      state = state.copyWith(isUploadingAvatar: false, success: true);
      return true;
    } catch (e) {
      AppLogger.error('uploadAvatar failed', e);
      state = state.copyWith(
          isUploadingAvatar: false,
          error: 'Failed to upload avatar: $e');
      return false;
    }
  }

  void clearState() => state = const ProfileState();
}

final profileNotifierProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref),
);

// ─── Real-time user profile stream ────────────────────────────────────────

final userProfileStreamProvider =
    StreamProvider.autoDispose.family<UserEntity, String>((ref, userId) {
  if (AppConfig.isDemoMode) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return Stream.error(Exception('Not authenticated'));
    return Stream.value(user);
  }
  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) throw Exception('User not found');
    return UserModel.fromFirestore(doc);
  });
});
