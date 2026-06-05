import 'package:flutter/material.dart';

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