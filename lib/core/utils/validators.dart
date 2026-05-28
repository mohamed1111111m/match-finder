import '../constants/app_strings.dart';

class AppValidators {
  AppValidators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return AppStrings.invalidEmail;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;
    if (value.length < 8) return AppStrings.weakPassword;
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;
    if (value != password) return AppStrings.passwordMismatch;
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    if (value.trim().length < 3) return 'Username must be at least 3 characters';
    if (value.trim().length > 30) return 'Username must be under 30 characters';
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : AppStrings.requiredField;
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    // Egyptian phone: 01xxxxxxxxx (11 digits) or +201xxxxxxxxx
    final regex = RegExp(r'^(\+20|0)?1[0-2,5]\d{8}$');
    if (!regex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Enter a valid Egyptian phone number (e.g. 01xxxxxxxxx)';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    final num = double.tryParse(value.trim());
    if (num == null) return '${fieldName ?? 'Value'} must be a number';
    if (num < 0) return '${fieldName ?? 'Value'} must be positive';
    return null;
  }

  static String? minParticipants(String? value) {
    final err = positiveNumber(value, 'Participants');
    if (err != null) return err;
    final n = int.tryParse(value!.trim());
    if (n == null || n < 2) return 'Minimum 2 participants required';
    if (n > 1024) return 'Maximum 1024 participants allowed';
    return null;
  }
}
