import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Chip 🔥 de STREAK (estilo TikTok) da ONG que está em 1º lugar no ranking
/// de transparência: "Há N dias em 1º lugar". Usado no header do perfil da
/// ONG, no card #1 do ranking e nas "ONGs em destaque" da Início.
///
/// REDESENHO (contraste MÁXIMO — 3ª tentativa): as versões anteriores usavam
/// fundo creme/claro e fogo laranja e o chip "sumia" (virava um pill quase
/// branco vazio). Agora o fundo é SÓLIDO e vibrante (gradiente laranja→vermelho
/// do fogo), o ícone de chama é BRANCO e o texto é BRANCO em negrito, com uma
/// sombra alaranjada para o chip saltar aos olhos tanto sobre o card claro
/// (selo dourado das "ONGs em destaque") quanto sobre o header verde e o tema
/// escuro.
///
/// [compacto] mostra só o NÚMERO de dias ao lado da chama (estilo streak do
/// TikTok), para caber nos cards pequenos; o significado completo fica no
/// Semantics. A versão normal escreve "Há N dias em 1º lugar".
class ChipFoguinho extends StatelessWidget {
  final int dias;
  final bool compacto;

  const ChipFoguinho({super.key, required this.dias, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    // Compacto = só o número (como o contador de "dias de sequência" do
    // TikTok); normal = frase inteira.
    final texto = compacto
        ? '$dias'
        : 'Há $dias ${dias == 1 ? "dia" : "dias"} em 1º lugar';
    return Semantics(
      label: 'Há $dias ${dias == 1 ? "dia" : "dias"} em primeiro lugar no '
          'ranking de transparência',
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compacto ? 8 : 12, vertical: compacto ? 4 : 6),
        decoration: BoxDecoration(
          // Fundo SÓLIDO (gradiente do fogo): laranja vibrante → vermelho.
          gradient: const LinearGradient(
            colors: [AppColors.fogo, AppColors.fogoEscuro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.fogo.withValues(alpha: 0.45),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded,
                size: compacto ? 15 : 17, color: Colors.white),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compacto ? 12 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
