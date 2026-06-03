import 'package:flutter/material.dart';

class AppTheme {

  static const primaryGreen =
      Color(0xFF0A8449);

  static ThemeData lightTheme =
      ThemeData(

    primaryColor: primaryGreen,

    scaffoldBackgroundColor:
        const Color(0xFFF5F7F6),

    colorScheme: ColorScheme.fromSeed(

      seedColor: primaryGreen,
    ),

    useMaterial3: true,
  );
}