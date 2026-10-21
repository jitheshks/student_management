class SupabaseConstants {
  SupabaseConstants._();

  // Tables
  static const String usersTable = 'users';
  static const String studentsTable = 'students';
  static const String staffTable = 'staff';
  static const String booksTable = 'books';
  static const String borrowRecordsTable = 'borrow_records';
  static const String feesTable = 'fee_records';

  // Storage Buckets
  static const String profilePicturesBucket = 'profile_pictures';

  // Edge Functions
  static const String deleteAuthUserFunction = 'delete-auth-user';
  static const String createUserAdminFunction = 'create-user-admin';
}
