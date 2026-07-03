import 'package:flutter/services.dart';

/// Converte o texto digitado para MAIUSCULAS enquanto o usuario digita.
/// Usado em campos como a UF do estado (ex.: "sp" -> "SP").
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Formata um valor em reais no padrão brasileiro: 1234.5 → "R$ 1.234,50".
/// Sem pacote intl — formatação manual simples (valores não-negativos do app).
String formatarReais(double valor) {
  final total = (valor.abs() * 100).round();
  final inteiro = (total ~/ 100).toString();
  final centavos = (total % 100).toString().padLeft(2, '0');

  final sb = StringBuffer();
  for (int i = 0; i < inteiro.length; i++) {
    final restantes = inteiro.length - i;
    sb.write(inteiro[i]);
    if (restantes > 1 && restantes % 3 == 1) sb.write('.');
  }
  final sinal = valor < 0 ? '-' : '';
  return '${sinal}R\$ $sb,$centavos';
}
