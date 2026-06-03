import 'package:flutter/material.dart';

class DescricaoScreen extends StatelessWidget {
  const DescricaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF0A8449);

    return Scaffold(
      // Estende o corpo para trás da AppBar para o gradiente ser total
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('Sobre o Projeto', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFA8DBC1), Color(0xFF0A8449)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // --- LOGO COM DESIGN ARREDONDADO ---
                Hero(
                  tag: 'logo_app',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/integrador.jpg',
                        height: 130,
                        width: 130,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Connect Ong',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))],
                  ),
                ),
                const SizedBox(height: 30),

                // --- CARD 1: DESCRIÇÃO GERAL ---
                _buildCard(
                  title: 'O Projeto',
                  icon: Icons.info_outline,
                  child: const Text(
                    'O Connect Ong é um projeto desenvolvido para facilitar a conexão entre doadores e receptores de doações, promovendo solidariedade e impacto social positivo. Nossa plataforma permite que pessoas e organizações encontrem, cadastrem e gerenciem doações de forma simples, rápida e segura.',
                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ),

                const SizedBox(height: 16),

                // --- CARD 2: FUNCIONALIDADES ---
                _buildCard(
                  title: 'Funcionalidades',
                  icon: Icons.star_border_rounded,
                  child: Column(
                    children: [
                      _buildListTile('Cadastro e busca de doações'),
                      _buildListTile('Cadastro de doadores e receptores'),
                      _buildListTile('Cadastro de ONGs'),
                      _buildListTile('Visualização de integrantes'),
                      _buildListTile('Interface intuitiva e moderna'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- CARD 3: DESENVOLVEDORES ---
                _buildCard(
                  title: 'Equipe de Desenvolvimento',
                  icon: Icons.groups_outlined,
                  child: Column(
                    children: [
                      _buildMemberItem('Gabriel'),
                      _buildMemberItem('Abner'),
                      _buildMemberItem('Luan'),
                      _buildMemberItem('Arthur'),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- RODAPÉ ---
                const Text(
                  'Desenvolvido por alunos do 3°DSN\nProjeto Integrador - 2024',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Funçao para criar os cards brancos elegantes
  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // Branco levemente transparente
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0A8449), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A8449),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(thickness: 1),
          ),
          child,
        ],
      ),
    );
  }

  // Estilo para os itens de funcionalidades (Checkmarks)
  Widget _buildListTile(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF0A8449), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // Estilo para os nomes dos desenvolvedores
  Widget _buildMemberItem(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Color(0xFF0A8449), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}