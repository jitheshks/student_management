import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_management/core/errors/app_exception.dart';
import 'package:student_management/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:student_management/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:student_management/shared/models/user_entity.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserEntity> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );

    final authUser = response.user;
    if (authUser == null) {
      throw const AppAuthException('Login failed: Invalid credentials.');
    }

    // Fetch user role from database
    final userRow =
        await _remoteDataSource.fetchUserRowByEmail(email) ??
        await _remoteDataSource.fetchUserRow(authUser.id);

    final UserEntity userEntity;
    if (userRow != null) {
      userEntity = UserEntity.fromJson(userRow);
    } else {
      // Fallback from auth metadata
      final meta = authUser.userMetadata ?? {};
      final roleStr = meta['role'] as String? ?? 'student';
      userEntity = UserEntity(
        id: authUser.id,
        email: authUser.email ?? email,
        role: UserRole.fromString(roleStr),
        createdAt: DateTime.tryParse(authUser.createdAt),
      );
    }

    // Cache session in SharedPreferences for legacy screens/controllers compatibility
    await _cacheSession(userEntity);

    return userEntity;
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
    await _clearCachedSession();
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    await _remoteDataSource.resetPasswordForEmail(email);
  }

  @override
  Future<void> verifyOtp({required String email, required String token}) async {
    final response = await _remoteDataSource.verifyOtp(
      email: email,
      token: token,
    );

    if (response.session == null) {
      throw const AppAuthException('Invalid or expired verification code.');
    }
  }

  @override
  Future<void> updateUserPassword(String newPassword) async {
    final response = await _remoteDataSource.updateUserPassword(newPassword);
    if (response.user == null) {
      throw const AppAuthException('Failed to update password.');
    }
  }

  @override
  Stream<UserEntity?> watchAuthState() {
    return _remoteDataSource.onAuthStateChange.asyncMap((authState) async {
      final session = authState.session;
      if (session == null) {
        await _clearCachedSession();
        return null;
      }

      final user = session.user;
      final userRow = await _remoteDataSource.fetchUserRow(user.id);
      if (userRow != null) {
        final entity = UserEntity.fromJson(userRow);
        await _cacheSession(entity);
        return entity;
      }

      final fallbackEntity = UserEntity(
        id: user.id,
        email: user.email ?? '',
        role: UserRole.fromString(user.userMetadata?['role']?.toString()),
        createdAt: DateTime.tryParse(user.createdAt),
      );
      await _cacheSession(fallbackEntity);
      return fallbackEntity;
    });
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final currentAuthUser = _remoteDataSource.currentAuthUser;
    if (currentAuthUser == null) return null;

    final userRow = await _remoteDataSource.fetchUserRow(currentAuthUser.id);
    if (userRow != null) {
      return UserEntity.fromJson(userRow);
    }

    return UserEntity(
      id: currentAuthUser.id,
      email: currentAuthUser.email ?? '',
      role: UserRole.fromString(
        currentAuthUser.userMetadata?['role']?.toString(),
      ),
      createdAt: DateTime.tryParse(currentAuthUser.createdAt),
    );
  }

  @override
  Future<String> createUser({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    return await _remoteDataSource.adminCreateUser(
      email: email,
      password: password,
      role: role.toDbString(),
    );
  }

  Future<void> _cacheSession(UserEntity user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userData', jsonEncode(user.toJson()));
      await prefs.setString('userRole', user.role.toDbString());
      await prefs.setString('user_id', user.id);
    } catch (e) {
      debugPrint('⚠️ [AuthRepositoryImpl] Session caching warning: $e');
    }
  }

  Future<void> _clearCachedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userData');
      await prefs.remove('userRole');
      await prefs.remove('user_id');
    } catch (e) {
      debugPrint('⚠️ [AuthRepositoryImpl] Session clearing warning: $e');
    }
  }
}
