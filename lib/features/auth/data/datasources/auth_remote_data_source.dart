import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_management/core/constants/supabase_constants.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/core/errors/error_handler.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client;
  final dynamic _isolatedHttpClient;

  AuthRemoteDataSource(this._client, {dynamic isolatedHttpClient})
    : _isolatedHttpClient = isolatedHttpClient;

  /// Current raw Supabase auth user
  User? get currentAuthUser => _client.auth.currentUser;

  /// Current raw Supabase session
  Session? get currentSession => _client.auth.currentSession;

  /// Stream of Supabase auth state changes
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Signs in with email and password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return response;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Signs out the active user session
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Initiates password reset email
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Verifies recovery OTP
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.recovery,
      );
      return response;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Updates current user password
  Future<UserResponse> updateUserPassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Fetches the public.users profile row by auth UID
  Future<Map<String, dynamic>?> fetchUserRow(String userId) async {
    try {
      final row =
          await _client
              .from(SupabaseConstants.usersTable)
              .select('id, email, role, created_at')
              .eq('id', userId)
              .maybeSingle();
      return row;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Fetches public.users profile row by email
  Future<Map<String, dynamic>?> fetchUserRowByEmail(String email) async {
    try {
      final row =
          await _client
              .from(SupabaseConstants.usersTable)
              .select('id, email, role, created_at')
              .eq('email', email.trim().toLowerCase())
              .maybeSingle();
      return row;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Safely creates a user without hijacking the active administrator session.
  /// 1. Tries invoking Edge Function 'create-user-admin' if deployed and available.
  /// 2. Falls back to an isolated GoTrueClient instance without session persistence
  ///    (autoRefreshToken: false, flowType: AuthFlowType.implicit, asyncStorage: null).
  ///    This strictly prevents overwriting the main client's session, even if Supabase
  ///    returns a session on signup when email confirmation is disabled.
  /// 3. Registers row in public.users table using the admin's authenticated _client.
  Future<String> adminCreateUser({
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    String? newAuthUid;

    final originalAdminSession = _client.auth.currentSession;
    final originalAdminUser = _client.auth.currentUser;

    // Upfront check: Privileged account creation requires an active authenticated session
    if (originalAdminSession == null || originalAdminUser == null) {
      throw const AppAuthException(
        'An active authenticated admin session is required to create accounts.',
      );
    }

    // Option A: Try invoking Edge Function if available
    try {
      final jwt = originalAdminSession.accessToken;
      final res = await _client.functions.invoke(
        SupabaseConstants.createUserAdminFunction,
        body: {'email': normalizedEmail, 'password': password, 'role': role},
        headers: {'Authorization': 'Bearer $jwt'},
      );

      final data = res.data;
      if (data is Map && data['userId'] != null) {
        newAuthUid = data['userId'].toString();
        debugPrint(
          '>>> [AuthRemoteDataSource] User created via Edge Function: $newAuthUid',
        );
      } else if (data is Map &&
          data['user'] is Map &&
          data['user']['id'] != null) {
        newAuthUid = data['user']['id'].toString();
        debugPrint(
          '>>> [AuthRemoteDataSource] User created via Edge Function: $newAuthUid',
        );
      }
    } catch (e) {
      debugPrint(
        'ℹ️ [AuthRemoteDataSource] Edge Function unavailable or errored: $e. Falling back to safe client signUp.',
      );
    }

    // Option B: Safe isolated client-side signUp fallback (DO NOT use _client.auth.signUp!)
    if (newAuthUid == null) {
      final baseSupabaseUrl = _client.rest.url.replaceAll('/rest/v1', '');
      final authUrl = '$baseSupabaseUrl/auth/v1';
      final apiKey =
          _client.auth.headers['apikey'] ?? _client.headers['apikey'] ?? '';

      if (apiKey.trim().isEmpty) {
        throw const AppAuthException(
          'Failed to initialize account creation: Supabase API key is missing.',
        );
      }

      final isolatedClient = GoTrueClient(
        url: authUrl,
        headers: {'apikey': apiKey},
        autoRefreshToken: false,
        flowType: AuthFlowType.implicit,
        httpClient: _isolatedHttpClient,
      );

      try {
        final response = await isolatedClient.signUp(
          email: normalizedEmail,
          password: password,
          data: {'role': role},
        );

        newAuthUid = response.user?.id;
        if (newAuthUid == null) {
          throw const AppAuthException(
            'Failed to create user: Auth response did not return a user ID.',
          );
        }
        debugPrint(
          '>>> [AuthRemoteDataSource] User created via isolated safe signUp: $newAuthUid',
        );
      } catch (e) {
        throw ErrorHandler.handleException(e);
      } finally {
        isolatedClient.dispose();
      }
    }

    // Strict runtime invariant check: fail with a clear error instead of risking session hijacking
    if (_client.auth.currentSession == null ||
        _client.auth.currentSession?.accessToken !=
            originalAdminSession.accessToken ||
        _client.auth.currentUser?.id != originalAdminUser.id) {
      throw const AppAuthException(
        'Critical security violation: Admin session was modified during student account creation.',
      );
    }

    assert(
      _client.auth.currentSession == originalAdminSession,
      'Session invariance violated: main client session was altered during adminCreateUser!',
    );
    assert(
      _client.auth.currentUser?.id == originalAdminUser.id,
      'Session invariance violated: main client user was altered during adminCreateUser!',
    );

    // Register user role in public.users table using the admin's authenticated _client
    try {
      await _client.from(SupabaseConstants.usersTable).upsert({
        'id': newAuthUid,
        'email': normalizedEmail,
        'role': role,
      });
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }

    return newAuthUid;
  }
}
