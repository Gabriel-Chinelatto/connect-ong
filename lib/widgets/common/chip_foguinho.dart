import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Chip 🔥 de STREAK (estilo TikTok) da ONG que está em 1º lugar no ranking
/// de transparência: "Há N dias em 1º lugar". Usado no header do perfil da
/// ONG, no card #1 do ranking e nas "ONGs em destaque" da Início.
///
/// REDESENHO (contraste forte): o chip antigo era laranja com chama branca e o
/// fogo "sumia". Agora o fundo é um CREME/laranja bem claro, o ícone de fogo é
/// LARANJA e o texto laranja escuro em negrito, com uma borda laranja fina que
/// delimita o chip. Assim ele destaca tanto sobre os cards claros (surface
/// branca / selo dourado das "ONGs em destaque") quanto sobre o tema escuro.
///
/// [compacto] encurta o texto ("N dias em 1º") para caber nos cards pequenos
/// — o número de dias aparece sempre no próprio chip.
class ChipFoguinho extends StatelessWidget {
  final int dias;
  final bool compacto;

  const ChipFoguinho({super.key, required this.dias, this.compacto = false});

  // Fundo creme/laranja bem claro (constante: legível nos dois temas porque o
  // chip tem fundo próprio, não é transparente).
  static const Color _fundo = Color(0xFFFFF1E0);

  @override
  Widget build(BuildContext context) {
    final texto = compacto
        ? '$dias ${dias == 1 ? "dia" : "dias"} em 1º'
        : 'Há $dias ${dias == 1 ? "dia" : "dias"} em 1º lugar';
    return Semantics(
      label: 'Há $dias ${dias == 1 ? "dia" : "dias"} em primeiro lugar no '
          'ranking de transparência',
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compacto ? 8 : 12, vertical: compacto ? 3 : 6),
        decoration: BoxDecoration(
          color: _fundo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.fogo, width: 1.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded,
                size: compacto ? 14 : 17, color: AppColors.fogo),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.fogoEscuro,
                  fontSize: compacto ? 10 : 13,
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
