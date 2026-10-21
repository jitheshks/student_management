import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'app_exception.dart';
import 'failure.dart';

class ErrorHandler {
  ErrorHandler._();

  /// Converts any caught error/exception into a domain [AppException].
  static AppException handleException(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is sb.AuthException) {
      return AppAuthException(_formatAuthErrorMessage(error), error.statusCode);
    }

    if (error is sb.PostgrestException) {
      return DatabaseException(_formatPostgrestErrorMessage(error), error.code);
    }

    if (error is SocketException ||
        error is HttpException ||
        error is TimeoutException) {
      return const NetworkException(
        'Unable to connect to the server. Please check your internet connection.',
      );
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const NetworkException(
          'Network request timed out or connection was refused. Please verify your connection.',
        );
      }
    }

    final errorString = error?.toString().toLowerCase() ?? '';
    if (errorString.contains('clientexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection reset by peer')) {
      return const NetworkException(
        'Unable to connect to the server. Please check your internet connection.',
      );
    }

    if (error is FormatException) {
      return ValidationException('Invalid data format: ${error.message}');
    }

    return ServerException(
      error?.toString() ?? 'An unexpected error occurred.',
    );
  }

  /// Converts any caught error/exception directly into a user-facing [Failure].
  static Failure handleFailure(dynamic error) {
    final exception = handleException(error);
    return Failure(message: exception.message, code: exception.code);
  }

  static String _formatAuthErrorMessage(sb.AuthException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return 'Invalid email or password. Please check your credentials.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (msg.contains('user not found')) {
      return 'No account found with this email address.';
    }
    if (msg.contains('token has expired') || msg.contains('otp expired')) {
      return 'Verification code has expired. Please request a new one.';
    }
    return error.message;
  }

  static String _formatPostgrestErrorMessage(sb.PostgrestException error) {
    // 23505: Unique constraint violation
    if (error.code == '23505') {
      if (error.message.contains('register_number')) {
        return 'A student with this register number already exists.';
      }
      if (error.message.contains('email')) {
        return 'An account with this email address already exists.';
      }
      return 'This record already exists in the system.';
    }

    // 42501: RLS policy violation
    if (error.code == '42501') {
      return 'Permission denied. You do not have access to perform this operation.';
    }

    // 23503: Foreign key violation
    if (error.code == '23503') {
      return 'Cannot complete operation because related records exist.';
    }

    return error.message;
  }
}
