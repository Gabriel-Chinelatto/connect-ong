import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Chip 🔥 de STREAK (estilo TikTok) da ONG que está em 1º lugar no ranking
/// de transparência: "Há N dias em 1º lugar". Usado no header do perfil da
/// ONG, no card #1 do ranking e nas "ONGs em destaque" da Início.
///
/// [compacto] encurta o texto ("N dias em 1º") para caber nos cards pequenos.
class ChipFoguinho extends StatelessWidget {
  final int dias;
  final bool compacto;

  const ChipFoguinho({super.key, required this.dias, this.compacto = false});

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
          gradient: const LinearGradient(
            colors: [AppColors.fogo, AppColors.fogoEscuro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔥', style: TextStyle(fontSize: compacto ? 11 : 14)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compacto ? 10 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
