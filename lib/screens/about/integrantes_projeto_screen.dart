import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Tela que lista os integrantes do projeto (equipe de desenvolvimento).
///
/// Exibe nome, foto e papel de cada estudante do 4°DSN responsavel pelo
/// Connect ONG. THEME-AWARE: cores do ColorScheme (legivel e coerente no claro
/// e no escuro); o verde da marca segue como acento.
class IntegrantesProjetoScreen extends StatelessWidget {
  const IntegrantesProjetoScreen({super.key});

  static const List<Map<String, String>> integrantes = [
    {
      'nome': 'Gabriel Chinelatto',
      'descricao': 'Aluno do 4°DSN, Desenvolvedor Back-end e Designer',
      'foto': 'assets/images/gabriel.jpg',
    },
    {
      'nome': 'Arthur Souza',
      'descricao': 'Aluno do 4°DSN, Designer e Tester',
      'foto': 'assets/images/arthur.jpg',
    },
    {
      'nome': 'Luan Felipe',
      'descricao': 'Aluno do 4°DSN, Desenvolvedor Back-end e Designer',
      'foto': 'assets/images/luan.png',
    },
    {
      'nome': 'Abner Viola',
      'descricao': 'Aluno do 4°DSN e Desenvolvedor Front-end',
      'foto': 'assets/images/abner.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Integrantes do Projeto',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: integrantes.length,
        itemBuilder: (context, i) {
          final integrante = integrantes[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 22),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(integrante['foto']!,
                      width: 82, height: 82, fit: BoxFit.cover),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              integrante['nome']!,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          integrante['descricao']!,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
