import 'package:flutter/material.dart';

class AppStyles {
  static const primaryColor = Color(0xFF1565C0);
  static const accentColor  = Color(0xFF42A5F5 );
  static const backgroundColor = Color(0xFFF5F5F5);
  static const cardColor  = Color(0xFFFFFFFF);
  static const errorColor  = Color(0xFFE53935);
  static const titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF212121),
  );

  static const subtitleStyle = TextStyle(
    fontSize: 16,
    color: Color(0xFF757575),
  );

  static const priceStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const paddingSmall = 8.0;
  static const paddingMedium  = 16.0;
  static const paddingLarge  = 24.0;

  static final elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  static final cardTheme = CardThemeData(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}