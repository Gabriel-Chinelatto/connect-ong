import 'package:flutter/material.dart';

class DescricaoScreen extends StatelessWidget {
  const DescricaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o Projeto'),
        backgroundColor: const Color(0xFF0A8449),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA8DBC1), Color(0xFF0A8449)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/integrador.jpg',
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Connect Ong',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A8449),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'O Connect Ong é um projeto desenvolvido para facilitar a conexão entre doadores e receptores de doações, promovendo solidariedade e impacto social positivo. Nossa plataforma permite que pessoas e organizações encontrem, cadastrem e gerenciem doações de forma simples, rápida e segura.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Funcionalidades:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A8449),
                  ),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '• Cadastro e busca de doações\n• Cadastro de doadores e receptores \n• Cadastro de ONGs\n• Visualização de integrantes do projeto\n• Interface intuitiva e moderna',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Desenvolvido por alunos do 3°DSN.\nProjeto Integrador - 2024',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 228, 228, 228),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
