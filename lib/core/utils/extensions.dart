import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
      ),
    );
  }
}

extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}

extension DateTimeExtensions on DateTime {
  String get formattedDate => DateFormat('MMM dd, yyyy').format(this);
  String get formattedDateTime =>
      DateFormat('MMM dd, yyyy • h:mm a').format(this);
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  bool get isUpcoming => isAfter(DateTime.now());
  bool get isPast => isBefore(DateTime.now());
}

extension DoubleExtensions on double {
  /// Format as Egyptian Pounds: "1,500.00 ج.م"
  String get egp {
    final formatted = NumberFormat('#,##0.00', 'en').format(this);
    return '$formatted ج.م';
  }

  /// Format as EGP without decimals: "1,500 ج.م"
  String get egpShort {
    final formatted = NumberFormat('#,##0', 'en').format(this);
    return '$formatted ج.م';
  }
}

extension IntExtensions on int {
  String get egp => toDouble().egp;
  String get egpShort => toDouble().egpShort;
}
