import 'package:flutter/material.dart';

/// Rodape padrao reutilizavel com creditos e direitos reservados do projeto.
class AppFooter extends StatelessWidget {

  const AppFooter({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(
        vertical: 24,
      ),

      child: Column(

        children: [

          Divider(
            color: Colors.grey.shade300,
          ),

          const SizedBox(
            height: 16,
          ),

          Text(

            '© 2025 Connect ONG — Todos os direitos reservados.',

            textAlign: TextAlign.center,

            style: TextStyle(

              color: Colors.grey.shade600,

              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(

            'Projeto acadêmico desenvolvido para a FECITEC.',

            textAlign: TextAlign.center,

            style: TextStyle(

              color: const Color.fromARGB(255, 158, 158, 158),

              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}