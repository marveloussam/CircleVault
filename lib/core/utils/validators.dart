abstract class Validators {
  /// Validates a Nigerian phone number in E.164 format: +234XXXXXXXXXX (10 digits after +234).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final cleaned = value.trim();
    // Accept +234XXXXXXXXXX — exactly 14 chars, starts with +234, followed by 10 digits
    final regex = RegExp(r'^\+234[7-9][01]\d{8}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid Nigerian phone number (+234XXXXXXXXXX).';
    }
    return null;
  }

  /// Validates email address format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final email = value.trim();
    // RFC 5322 compliant email regex (simplified but comprehensive)
    final regex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
    );
    if (!regex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    // Additional validation - check for common domains format
    if (!email.contains('.') || email.startsWith('@') || email.endsWith('.')) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates password — minimum 6 characters (matches Firebase's requirement).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    // Optional: Add strength requirements
    if (value.length > 128) {
      return 'Password is too long.';
    }
    return null;
  }

  /// Validates a full name — minimum 2 characters, maximum 50.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required.';
    }
    final name = value.trim();
    if (name.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (name.length > 50) {
      return 'Name must be under 50 characters.';
    }
    // Check for only allowed characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(name)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes.';
    }
    return null;
  }

  /// Validates a circle name — 3–50 characters.
  static String? validateCircleName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Circle name is required.';
    }
    final name = value.trim();
    if (name.length < 3) {
      return 'Circle name must be at least 3 characters.';
    }
    if (name.length > 50) {
      return 'Circle name must be under 50 characters.';
    }
    // Allow letters, numbers, spaces, and common punctuation
    if (!RegExp(r"^[a-zA-Z0-9\s\-',.&]+$").hasMatch(name)) {
      return 'Circle name contains invalid characters.';
    }
    return null;
  }

  /// Validates a contribution amount in Naira — positive integer.
  static String? validateContributionAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contribution amount is required.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid amount in Naira (e.g. 5000).';
    }
    if (parsed < 100) {
      return 'Minimum contribution is NGN 100.';
    }
    if (parsed > 10000000) { // 10 million Naira max
      return 'Maximum contribution is NGN 10,000,000.';
    }
    return null;
  }

  /// Validates total members count — between 2 and 50.
  static String? validateTotalMembers(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Total members is required.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number.';
    }
    if (parsed < 2) {
      return 'A circle must have at least 2 members.';
    }
    if (parsed > 50) {
      return 'A circle can have at most 50 members.';
    }
    return null;
  }

  /// Validates a 6-digit OTP.
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required.';
    }
    final otp = value.trim();
    if (otp.length != 6) {
      return 'OTP must be exactly 6 digits.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'OTP can only contain numbers.';
    }
    return null;
  }

  /// Validates a bank account number (10 digits for Nigerian banks).
  static String? validateBankAccount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required.';
    }
    final account = value.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(account)) {
      return 'Enter a valid 10-digit account number.';
    }
    return null;
  }

  /// Validates that two passwords match.
  static String? validatePasswordMatch(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password.';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }


  /// Validates that a string is not empty.
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  /// Validates a string length range.
  static String? validateLength(String? value, {int min = 0, int max = 255, String fieldName = 'This field'}) {
    if (value == null) return '$fieldName is required.';
    final length = value.trim().length;
    if (length < min) {
      return '$fieldName must be at least $min characters.';
    }
    if (length > max) {
      return '$fieldName must be at most $max characters.';
    }
    return null;
  }

  /// Validates that a value is a number within a range.
  static String? validateNumber(String? value, {int? min, int? max, String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a valid number.';
    }
    if (min != null && parsed < min) {
      return '$fieldName must be at least $min.';
    }
    if (max != null && parsed > max) {
      return '$fieldName must be at most $max.';
    }
    return null;
  }
}