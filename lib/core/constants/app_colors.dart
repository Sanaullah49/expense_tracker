import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF5541D7);
  static const Color primaryDeep = Color(0xFF3B2DAB);
  static const Color accent = Color(0xFFFD79A8);

  static const Color secondary = Color(0xFF00CEC9);
  static const Color secondaryLight = Color(0xFF81ECEC);

  static const Color backgroundLight = Color(0xFFF5F6FB);
  static const Color backgroundDark = Color(0xFF0F1020);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1B2F);
  static const Color surfaceElevatedDark = Color(0xFF222441);
  static const Color surfaceMutedLight = Color(0xFFEEF0F7);
  static const Color surfaceMutedDark = Color(0xFF252644);

  static const Color textPrimaryLight = Color(0xFF1B1D2A);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textPrimaryDark = Color(0xFFF5F6FB);
  static const Color textSecondaryDark = Color(0xFFB2BEC3);
  static const Color textTertiaryDark = Color(0xFF7C8595);

  static const Color borderLight = Color(0xFFE6E8F0);
  static const Color borderDark = Color(0xFF2E3052);

  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);

  static const Color income = Color(0xFF00B894);
  static const Color expense = Color(0xFFE74C3C);
  static const Color transfer = Color(0xFF74B9FF);

  static const List<Color> categoryColors = [
    Color(0xFFE74C3C),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF03A9F4),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFFCDDC39),
    Color(0xFFFFEB3B),
    Color(0xFFFFC107),
    Color(0xFFFF9800),
    Color(0xFFFF5722),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7B6CFB), Color(0xFF6C5CE7), Color(0xFF5541D7)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primarySoftGradient = LinearGradient(
    colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFFF7675)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradientLight = LinearGradient(
    colors: [Color(0xFFF5F6FB), Color(0xFFEEF0F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [Color(0xFF0F1020), Color(0xFF161830)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static List<BoxShadow> softShadow({Color? color}) => [
    BoxShadow(
      color: (color ?? const Color(0xFF6C5CE7)).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> heroShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 28,
      offset: const Offset(0, 14),
      spreadRadius: -4,
    ),
  ];
}
