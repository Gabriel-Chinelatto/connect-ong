import 'package:flutter/material.dart';

/// Paleta de cores da marca Connect ONG (fonte unica de verdade).
///
/// Use SEMPRE estas constantes em vez de cores soltas (`Color(0xFF...)`).
/// Isto garante consistencia visual e permite ajustar a identidade em um
/// unico lugar. Base da identidade: o verde da marca.
class AppColors {
  AppColors._();

  // ---- Verde da marca ----
  static const Color primary = Color(0xFF0A8449);
  static const Color primaryDark = Color(0xFF076637);
  static const Color primaryLight = Color(0xFFA8DBC1);

  /// Verde bem suave, para fundos de destaque, chips e "indicador" da nav.
  static const Color primarySurface = Color(0xFFE7F4EC);

  /// Cor de conteudo sobre o verde primario (texto/icone).
  static const Color onPrimary = Colors.white;

  // ---- Superficies e fundo ----
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;

  /// Fundo levemente cinza para "cards" secundarios / secoes.
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // ---- Texto ----
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  /// Texto ainda mais claro (legendas, placeholders, metadados).
  static const Color textTertiary = Color(0xFF94A3B8);

  // ---- Bordas e divisores ----
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF1F5);

  // ---- Estados / feedback ----
  static const Color success = Color(0xFF0A8449);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2563EB);

  // ---- Medalhas (transparencia / ranking) ----
  // Centralizadas aqui para eliminar a duplicacao de magic numbers que existia
  // nas telas de ranking e perfil publico.
  static const Color ouro = Color(0xFFF59E0B);
  static const Color prata = Color(0xFF9CA3AF);
  static const Color bronze = Color(0xFFCD7F32);
}
