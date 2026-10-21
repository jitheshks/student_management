class InputValidators {
  InputValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(r'^[0-9]{10}$');

  /// Validates email address format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password presence and length.
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Validates required text fields (name, department, title, etc.).
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates standard/class selection.
  static String? validateStandard(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a standard';
    }
    return null;
  }

  /// Validates designation selection.
  static String? validateDesignation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a designation';
    }
    return null;
  }

  /// Validates 10-digit phone number.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Validates student register number format.
  static String? validateRegisterNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Register number is required';
    }
    return null;
  }
}
