class Validators {
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? amount(String? value, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (min != null && amount < min) {
      return 'Amount must be at least $min';
    }

    if (max != null && amount > max) {
      return 'Amount must not exceed $max';
    }

    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 10 || cleaned.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static String? name(String? value, {int minLength = 2, int maxLength = 50}) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < minLength) {
      return 'Name must be at least $minLength characters';
    }

    if (value.trim().length > maxLength) {
      return 'Name must not exceed $maxLength characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  static String? title(
    String? value, {
    int minLength = 1,
    int maxLength = 100,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }

    if (value.trim().length < minLength) {
      return 'Title must be at least $minLength character(s)';
    }

    if (value.trim().length > maxLength) {
      return 'Title must not exceed $maxLength characters';
    }

    return null;
  }

  static String? note(String? value, {int maxLength = 500}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (value.trim().length > maxLength) {
      return 'Note must not exceed $maxLength characters';
    }

    return null;
  }

  static String? date(DateTime? value, {DateTime? minDate, DateTime? maxDate}) {
    if (value == null) {
      return 'Date is required';
    }

    if (minDate != null && value.isBefore(minDate)) {
      return 'Date cannot be before ${minDate.toString().split(' ')[0]}';
    }

    if (maxDate != null && value.isAfter(maxDate)) {
      return 'Date cannot be after ${maxDate.toString().split(' ')[0]}';
    }

    return null;
  }

  static String? futureDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }

    if (value.isBefore(DateTime.now())) {
      return 'Date must be in the future';
    }

    return null;
  }

  static String? pastDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }

    if (value.isAfter(DateTime.now())) {
      return 'Date must be in the past';
    }

    return null;
  }

  static String? pin(String? value, {int length = 4}) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }

    if (value.length != length) {
      return 'PIN must be $length digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }

    return null;
  }

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  static String? percentage(String? value, {double min = 0, double max = 100}) {
    if (value == null || value.trim().isEmpty) {
      return 'Percentage is required';
    }

    final percentage = double.tryParse(value.replaceAll('%', '').trim());
    if (percentage == null) {
      return 'Please enter a valid percentage';
    }

    if (percentage < min || percentage > max) {
      return 'Percentage must be between $min and $max';
    }

    return null;
  }

  static String? integer(String? value, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final intValue = int.tryParse(value.trim());
    if (intValue == null) {
      return 'Please enter a valid whole number';
    }

    if (min != null && intValue < min) {
      return 'Value must be at least $min';
    }

    if (max != null && intValue > max) {
      return 'Value must not exceed $max';
    }

    return null;
  }

  static String? combine(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
