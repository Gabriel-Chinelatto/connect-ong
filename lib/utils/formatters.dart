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
