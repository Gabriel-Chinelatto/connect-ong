import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Fabrica central de temas (Material 3) do app do doador.
///
/// Constroi os temas claro/escuro a partir da paleta da marca e aplica
/// ajustes de acessibilidade: fonte amigavel a dislexia (Lexend) e modo de
/// alto contraste. E consumido pelo MaterialApp via [ConfigController].
class AppTheme {
  // Mantidos como apelido da paleta (compatibilidade com telas existentes).
  static const Color primaryGreen = AppColors.primary;
  static const Color lightGreen = AppColors.primaryLight;

  // Tema padrao (claro) — compatibilidade.
  static ThemeData get theme => light();

  static ThemeData light({bool dislexia = false, bool altoContraste = false}) =>
      _build(Brightness.light, dislexia, altoContraste);

  static ThemeData dark({bool dislexia = false, bool altoContraste = false}) =>
      _build(Brightness.dark, dislexia, altoContraste);

  static ThemeData _build(
      Brightness brightness, bool dislexia, bool altoContraste) {
    final bool escuro = brightness == Brightness.dark;

    final Color bg = escuro ? const Color(0xFF121212) : AppColors.background;
    final Color surface = escuro ? const Color(0xFF1E1E1E) : AppColors.surface;
    final Color texto = altoContraste
        ? (escuro ? Colors.white : Colors.black)
        : (escuro ? Colors.white70 : AppColors.textPrimary);

    // Fonte amigavel para dislexia (Lexend) ou a padrao (Poppins).
    final TextTheme base =
        dislexia ? GoogleFonts.lexendTextTheme() : GoogleFonts.poppinsTextTheme();
    final TextTheme textTheme =
        base.apply(bodyColor: texto, displayColor: texto);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: texto,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: altoContraste
              ? BorderSide(color: texto, width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
      // Barra de navegacao inferior (shell do app) com a cara da marca:
      // fundo neutro, "pilula" verde suave no item ativo e icone/rotulo em verde.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 3,
        height: 68,
        indicatorColor: escuro
            ? AppColors.primary.withValues(alpha: 0.30)
            : AppColors.primarySurface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool ativo = states.contains(WidgetState.selected);
          return IconThemeData(
            color: ativo
                ? AppColors.primary
                : (escuro ? Colors.white60 : AppColors.textSecondary),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool ativo = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
            color: ativo
                ? AppColors.primary
                : (escuro ? Colors.white60 : AppColors.textSecondary),
          );
        }),
      ),
    );
  }
}
