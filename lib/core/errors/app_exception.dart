/// Sealed application exception hierarchy.
sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Authentication and session exceptions.
class AppAuthException extends AppException {
  const AppAuthException(super.message, [super.code]);
}

/// Database, Postgrest, and RLS exceptions.
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.code]);
}

/// Network, connectivity, and HTTP client exceptions.
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

/// Client-side validation and form input exceptions.
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);
}

/// Resource not found exceptions.
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.code]);
}

/// Server-side or Edge Function exceptions.
class ServerException extends AppException {
  const ServerException(super.message, [super.code]);
}
