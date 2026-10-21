class AppConstants {
  AppConstants._();

  static const String appName = 'Student Management System';

  // Standards / Classes list
  static const List<String> standards = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th',
    '9th',
    '10th',
  ];

  // Staff designations list
  static const List<String> designations = [
    'Teacher',
    'Librarian',
    'Staff',
    'Accountant',
    'Principal',
  ];

  // Pagination & limits
  static const int defaultPageSize = 20;
  static const int defaultLoanDurationDays = 14;
  static const int defaultBookCopies = 4;
  static const int otpCooldownSeconds = 60;
}
