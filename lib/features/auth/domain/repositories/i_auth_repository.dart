import 'package:student_management/shared/models/user_entity.dart';

abstract class IAuthRepository {
  /// Signs in a user with [email] and [password].
  Future<UserEntity> signInWithPassword({
    required String email,
    required String password,
  });

  /// Signs out the currently authenticated user.
  Future<void> signOut();

  /// Initiates password reset for the specified [email].
  Future<void> resetPasswordForEmail(String email);

  /// Verifies the OTP [token] for [email].
  Future<void> verifyOtp({required String email, required String token});

  /// Updates the currently authenticated user's password to [newPassword].
  Future<void> updateUserPassword(String newPassword);

  /// Stream of user auth and session state changes.
  Stream<UserEntity?> watchAuthState();

  /// Gets the currently authenticated user entity, or null.
  Future<UserEntity?> getCurrentUser();

  /// Safely creates a student or staff user account without altering or hijacking
  /// the active administrator/staff session. Returns the new Auth UID.
  Future<String> createUser({
    required String email,
    required String password,
    required UserRole role,
  });
}
