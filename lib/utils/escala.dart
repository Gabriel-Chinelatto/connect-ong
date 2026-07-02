import 'package:flutter/material.dart';

/// Fator de escala de fonte efetivo (1.0 = padrao), limitado a 1.6.
///
/// Use para dimensionar alturas fixas e razoes de aspecto de grades junto com
/// o tamanho de fonte escolhido nas Configurações — evita overflow de pixels
/// quando o usuário aumenta a fonte (acessibilidade).
double fatorFonte(BuildContext context) {
  final fator = MediaQuery.textScalerOf(context).scale(14) / 14;
  return fator.clamp(1.0, 1.6);
}
