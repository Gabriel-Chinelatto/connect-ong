import 'package:flutter/material.dart';

class IntegrantesProjetoScreen extends StatelessWidget {
  const IntegrantesProjetoScreen({super.key});

  final List<Map<String, String>> integrantes = const [
    {
      'nome': 'Lucas Henrique Martins',
      'descricao': 'Aluno do 3°DSN, Desenvolvedor full-stack e Líder do Projeto',
      'foto': 'assets/images/lucas.jpg',
    },
    {
      'nome': 'Gabriel Chinelatto',
      'descricao': 'Desenvolvedor Back-end e Designer',
      'foto': 'assets/images/gabriel.jpg',
    },
    {
      'nome': 'Arthur Souza',
      'descricao': 'Aluno do 3°DSN, Designer e Tester',
      'foto': 'assets/images/arthur.jpg',
    },
    {
      'nome': 'Luan Felipe',
      'descricao': 'Aluno do 3°DSN, Desenvolvedor Back-end e Designer',
      'foto': 'assets/images/luan.png',
    },
    {
      'nome': 'Abner Viola',
      'descricao': 'Aluno do 3°DSN e Desenvolvedor Front-end',
      'foto': 'assets/images/abner.jpg',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Integrantes do Projeto')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: integrantes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, i) {
          final integrante = integrantes[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            shadowColor: Colors.black45,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(integrante['foto']!),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          integrante['nome']!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A8449),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          integrante['descricao']!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF066537),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
