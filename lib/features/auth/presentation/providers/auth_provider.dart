import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

// ─── Repository provider ───────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSourceImpl(),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// ─── Auth state stream ─────────────────────────────────────────────────────
// Provides the currently authenticated user or null.

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ─── Current user convenience provider ────────────────────────────────────

final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// ─── Auth actions notifier ─────────────────────────────────────────────────

enum AuthStatus { initial, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  const AuthState({this.status = AuthStatus.initial, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) => AuthState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );

  bool get isLoading => status == AuthStatus.loading;
  bool get isError => status == AuthStatus.error;
  bool get isSuccess => status == AuthStatus.success;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final GoogleSignInUseCase _googleSignIn;
  final SignOutUseCase _signOut;
  final ForgotPasswordUseCase _forgotPassword;

  AuthNotifier(AuthRepository repository)
      : _repository = repository,
        _signIn = SignInUseCase(repository),
        _signUp = SignUpUseCase(repository),
        _googleSignIn = GoogleSignInUseCase(repository),
        _signOut = SignOutUseCase(repository),
        _forgotPassword = ForgotPasswordUseCase(repository),
        super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _signIn(SignInParams(email: email, password: password));
    return result.fold(
      (failure) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (user) async {
        state = state.copyWith(status: AuthStatus.success);
        await NotificationService.instance.saveTokenForUser(user.uid);
        return true;
      },
    );
  }

  Future<bool> signUp(String email, String password, String username) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result =
        await _signUp(SignUpParams(email: email, password: password, username: username));
    return result.fold(
      (failure) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (user) async {
        state = state.copyWith(status: AuthStatus.success);
        await NotificationService.instance.saveTokenForUser(user.uid);
        return true;
      },
    );
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _googleSignIn();
    return result.fold(
      (failure) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (user) async {
        state = state.copyWith(status: AuthStatus.success);
        await NotificationService.instance.saveTokenForUser(user.uid);
        return true;
      },
    );
  }

  Future<void> signOut() async {
    await _signOut();
    state = const AuthState();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _forgotPassword(email);
    return result.fold(
      (failure) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.success);
        return true;
      },
    );
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _repository.deleteAccount();
    return result.fold(
      (failure) {
        state = state.copyWith(
            status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = const AuthState();
        return true;
      },
    );
  }

  void clearError() => state = state.copyWith(status: AuthStatus.initial);
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
