import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';

/// Avatar da mascote "Dora" — a assistente de doacao do Connect ONG.
///
/// Um coracao verde fofinho e acolhedor (SVG original em
/// `assets/images/dora_mascote.svg`), dentro de um circulo suave na cor da
/// marca. Usado como avatar no cabecalho do chat, ao lado das bolhas da Dora,
/// no botao do lado da busca e na bolha de boas-vindas — sempre com o mesmo
/// visual, em qualquer tamanho.
class DoraAvatar extends StatelessWidget {
  /// Diametro do circulo (o mascote ocupa ~68% dele, com respiro nas bordas).
  final double tamanho;

  /// Cor de fundo do circulo. Por padrao um verde bem suave da marca.
  final Color? fundo;

  const DoraAvatar({super.key, this.tamanho = 40, this.fundo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: fundo ?? AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/images/dora_mascote.svg',
        width: tamanho * 0.7,
        height: tamanho * 0.7,
        semanticsLabel: 'Dora, assistente de doacao',
      ),
    );
  }
}
