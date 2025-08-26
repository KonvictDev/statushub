import 'package:flutter/material.dart';

class AppColors {
  // 🎨 Brand Colors
  static const Color primary = Color(0xFF075E54);
  static const Color primaryDark = Color(0xFF0052CC);
  static const Color primaryLight = Color(0xFF4D94FF);

  static const Color secondary = Color(0xFFFF6B35);
  static const Color secondaryDark = Color(0xFFCC552A);
  static const Color secondaryLight = Color(0xFFFF8C5D);

  // 🖤 Neutral Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFF9E9E9E);
  static const Color grayLight = Color(0xFFF5F5F5);
  static const Color grayDark = Color(0xFF424242);

  // ✅ Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // 🏞 Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF212121);

  // 📝 Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // ⬜ Borders
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);

  // 🌈 Gradients
  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static LinearGradient secondaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );

  // 🟢 Material System Colors (for quick reuse)
  static const Color deepPurple = Colors.deepPurple;
  static const Color orangeAccent = Colors.orangeAccent;
  static const Color white70 = Colors.white70;
  static const Color overlayBlack = Colors.black54;
  static const Color lightGrayBackground = Color(0xFFF5F5F5); // alias for grayLight

// StatusTab colors
  static const Color sortMenuBackground = Color(0xFFA5D6A7); // same as green.shade200
  static const Color sortText = Colors.black;

  static const Color chipSelected = Color(0xFFC8E6C9); // same as green.shade100
  static const Color chipCheckmark = Colors.green;

  static const Color emptyIcon = Colors.grey;
  static const Color emptyText = Colors.grey;

}

// 🌟 Extension for easy theme access
extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors();
}
