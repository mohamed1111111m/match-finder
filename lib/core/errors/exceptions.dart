/// Thrown from data-layer and caught by repositories,
/// which convert them into [Failure] objects.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({this.message = 'Server error', this.statusCode});
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'No internet connection'});
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'Cache error'});
  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String code;
  final String message;
  const AuthException({required this.code, required this.message});
  @override
  String toString() => 'AuthException($code): $message';
}

class PaymentException implements Exception {
  final String message;
  const PaymentException({required this.message});
  @override
  String toString() => 'PaymentException: $message';
}

class PermissionException implements Exception {
  final String message;
  const PermissionException({this.message = 'Permission denied'});
  @override
  String toString() => 'PermissionException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException({this.message = 'Resource not found'});
  @override
  String toString() => 'NotFoundException: $message';
}
