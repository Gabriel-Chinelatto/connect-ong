import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Fabrica central de temas (Material 3) do app do doador.
///
/// Constroi os temas claro/escuro a partir da paleta da marca e aplica
/// ajustes de acessibilidade: fonte amigavel a dislexia (Lexend), modo de
/// alto contraste REAL (fundos puros + bordas fortes + verde AA) e navegacao
/// simplificada (transicoes de tela em fade curto). E consumido pelo
/// MaterialApp via [ConfigController].
class AppTheme {
  // Mantidos como apelido da paleta (compatibilidade com telas existentes).
  static const Color primaryGreen = AppColors.primary;
  static const Color lightGreen = AppColors.primaryLight;

  // ----- Verdes de alto contraste (AA) -----
  // No claro, o verde da marca (#0A8449) escurecido para #06603A: contraste
  // ~7.7:1 com branco (AA/AAA para texto). No escuro, um verde mais claro
  // (#35C97F): contraste ~9.8:1 com preto puro.
  static const Color _verdeContrasteClaro = Color(0xFF06603A);
  static const Color _verdeContrasteEscuro = Color(0xFF35C97F);

  // Tema padrao (claro) — compatibilidade.
  static ThemeData get theme => light();

  static ThemeData light({
    bool dislexia = false,
    bool altoContraste = false,
    bool navegacaoSimplificada = false,
  }) =>
      _build(Brightness.light, dislexia, altoContraste, navegacaoSimplificada);

  static ThemeData dark({
    bool dislexia = false,
    bool altoContraste = false,
    bool navegacaoSimplificada = false,
  }) =>
      _build(Brightness.dark, dislexia, altoContraste, navegacaoSimplificada);

  static ThemeData _build(Brightness brightness, bool dislexia,
      bool altoContraste, bool navegacaoSimplificada) {
    final bool escuro = brightness == Brightness.dark;

    // ----- Cores base (alto contraste = fundos/textos PUROS) -----
    final Color bg = altoContraste
        ? (escuro ? const Color(0xFF000000) : const Color(0xFFFFFFFF))
        : (escuro ? const Color(0xFF121212) : AppColors.background);
    final Color surface = altoContraste
        ? bg
        : (escuro ? const Color(0xFF1E1E1E) : AppColors.surface);
    final Color texto = altoContraste
        ? (escuro ? Colors.white : Colors.black)
        : (escuro ? Colors.white70 : AppColors.textPrimary);

    // Verde da marca ajustado para contraste AA quando o modo esta ligado.
    final Color primaria = altoContraste
        ? (escuro ? _verdeContrasteEscuro : _verdeContrasteClaro)
        : AppColors.primary;
    final Color sobrePrimaria =
        altoContraste && escuro ? Colors.black : Colors.white;

    // Bordas fortes de cards/inputs e divisores visiveis no alto contraste.
    final Color corBorda = escuro ? Colors.white : Colors.black;

    // Fonte amigavel para dislexia (Lexend) ou a padrao (Poppins).
    final TextTheme base =
        dislexia ? GoogleFonts.lexendTextTheme() : GoogleFonts.poppinsTextTheme();
    final TextTheme textTheme =
        base.apply(bodyColor: texto, displayColor: texto);

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: primaria,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      colorScheme: altoContraste
          // Superficies puras + textos puros + "outlines" fortes: as telas que
          // usam cs.surface/cs.outlineVariant (cards da Inicio, chips, etc.)
          // ganham bordas e contraste visiveis automaticamente.
          ? scheme.copyWith(
              primary: primaria,
              onPrimary: sobrePrimaria,
              surface: surface,
              onSurface: texto,
              onSurfaceVariant: texto,
              surfaceContainerHighest:
                  escuro ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
              outline: corBorda,
              outlineVariant: corBorda,
            )
          : scheme,
      // Navegacao simplificada: troca de tela em fade CURTO (sem deslizes
      // longos) para reduzir movimento. Vale para todos os MaterialPageRoute.
      pageTransitionsTheme: navegacaoSimplificada
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _TransicaoFadeCurta(),
                TargetPlatform.iOS: _TransicaoFadeCurta(),
                TargetPlatform.windows: _TransicaoFadeCurta(),
                TargetPlatform.macOS: _TransicaoFadeCurta(),
                TargetPlatform.linux: _TransicaoFadeCurta(),
                TargetPlatform.fuchsia: _TransicaoFadeCurta(),
              },
            )
          : null,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: texto,
      ),
      // Divisores visiveis no alto contraste (na paleta normal, o padrao).
      dividerTheme: altoContraste
          ? DividerThemeData(color: corBorda, thickness: 1)
          : null,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaria,
          foregroundColor: sobrePrimaria,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        // Alto contraste: borda solida de 1.5px em vez de sombra.
        elevation: altoContraste ? 0 : 4,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: altoContraste
              ? BorderSide(color: corBorda, width: 1.5)
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: altoContraste
              ? BorderSide(color: corBorda, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: altoContraste
              ? BorderSide(color: corBorda, width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primaria,
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
        indicatorColor: altoContraste
            ? primaria.withValues(alpha: escuro ? 0.35 : 0.18)
            : (escuro
                ? AppColors.primary.withValues(alpha: 0.30)
                : AppColors.primarySurface),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool ativo = states.contains(WidgetState.selected);
          return IconThemeData(
            color: ativo
                ? primaria
                : (altoContraste
                    ? texto
                    : (escuro ? Colors.white60 : AppColors.textSecondary)),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool ativo = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
            color: ativo
                ? primaria
                : (altoContraste
                    ? texto
                    : (escuro ? Colors.white60 : AppColors.textSecondary)),
          );
        }),
      ),
    );
  }
}

/// Transicao de rota do modo "navegacao simplificada": fade curto (~120ms),
/// sem deslocamento — menos movimento na tela para quem se distrai ou enjoa
/// com animacoes.
class _TransicaoFadeCurta extends PageTransitionsBuilder {
  const _TransicaoFadeCurta();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
