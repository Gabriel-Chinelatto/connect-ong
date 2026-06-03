import 'package:flutter/material.dart';

class AppTheme {

  static const Color primaryGreen =
      Color(0xFF0A8449);

  static const Color lightGreen =
      Color(0xFFA8DBC1);

  static ThemeData get theme {

    return ThemeData(

      useMaterial3: true,

      scaffoldBackgroundColor:
          const Color(0xFFF5F7FA),

      colorScheme: ColorScheme.fromSeed(

        seedColor: primaryGreen,

        primary: primaryGreen,
      ),

      appBarTheme: const AppBarTheme(

        backgroundColor:
            Colors.transparent,

        elevation: 0,

        centerTitle: true,

        foregroundColor:
            Colors.black87,
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(

        style: ElevatedButton.styleFrom(

          backgroundColor:
              primaryGreen,

          foregroundColor:
              Colors.white,

          padding:
              const EdgeInsets.symmetric(

            vertical: 16,
          ),

          shape: RoundedRectangleBorder(

            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),

      cardTheme: CardThemeData(

        elevation: 4,

        color: Colors.white,

        shape: RoundedRectangleBorder(

          borderRadius:
              BorderRadius.circular(20),
        ),
      ),

      inputDecorationTheme:
          InputDecorationTheme(

        filled: true,

        fillColor: Colors.white,

        border: OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(16),

          borderSide: BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(16),

          borderSide: const BorderSide(

            color: primaryGreen,

            width: 2,
          ),
        ),
      ),
    );
  }
}