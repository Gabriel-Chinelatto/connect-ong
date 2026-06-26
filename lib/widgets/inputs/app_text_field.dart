import 'package:flutter/material.dart';

/// Campo de texto padrao do app, com icone-prefixo e dica (hint).
///
/// Reutilizado em formularios (ex.: login). Suporta campo de senha via
/// [obscureText].
class AppTextField extends StatelessWidget {

  final TextEditingController controller;

  final String hint;

  final IconData icon;

  final bool obscureText;

  const AppTextField({

    super.key,

    required this.controller,

    required this.hint,

    required this.icon,

    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {

    return TextField(

      controller: controller,

      obscureText: obscureText,

      decoration: InputDecoration(

        hintText: hint,

        prefixIcon: Icon(icon),

        contentPadding:
            const EdgeInsets.symmetric(

          vertical: 20,
          horizontal: 16,
        ),
      ),
    );
  }
}