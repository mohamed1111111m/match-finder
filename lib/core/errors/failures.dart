import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Network / connectivity
class NetworkFailure extends Failure {
  const NetworkFailure(
      [super.message = 'No internet connection. Please check your network.']);
}

// Firebase / server errors
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again.']);
}

// Authentication specific
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('No account found with this email.');
}

class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure() : super('Incorrect password.');
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure()
      : super('An account already exists with this email.');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure()
      : super('Password must be at least 8 characters.');
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure()
      : super('Too many attempts. Please try again later.');
}

// Permission / authorization
class PermissionFailure extends Failure {
  const PermissionFailure(
      [super.message = 'You do not have permission for this action.']);
}

// Cache / local storage
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data error.']);
}

// Payment failures
class PaymentFailure extends Failure {
  const PaymentFailure(super.message);
}

class PaymentVerificationFailure extends PaymentFailure {
  const PaymentVerificationFailure()
      : super('Payment could not be verified. Contact support.');
}

// Tournament
class TournamentFullFailure extends Failure {
  const TournamentFullFailure()
      : super('Tournament is full. No more spots available.');
}

class AlreadyJoinedFailure extends Failure {
  const AlreadyJoinedFailure() : super('You have already joined this tournament.');
}

// Requires recent sign-in (Firebase re-auth)
class RecentLoginRequiredFailure extends AuthFailure {
  const RecentLoginRequiredFailure() : super('requires-recent-login');
}

// Generic unexpected
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
