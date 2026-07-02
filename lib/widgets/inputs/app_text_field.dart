import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto padrao do app, com icone-prefixo e dica (hint).
///
/// Reutilizado em formularios (login, cadastro, perfil, doacao). Alem do
/// [obscureText] para senha, expoe [keyboardType], [maxLength],
/// [inputFormatters] e [textInputAction] para permitir teclados e validacoes
/// corretos por campo. Quando [obscureText] e true, mostra automaticamente um
/// botao de "mostrar/ocultar senha".
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _oculto = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _oculto,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon),
        // Esconde o contador padrao do maxLength (evita "0/60" poluindo a UI);
        // o limite continua valendo.
        counterText: '',
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _oculto ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                    _oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _oculto = !_oculto),
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      ),
    );
  }
}
