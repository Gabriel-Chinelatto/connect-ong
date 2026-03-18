import 'package:flutter/material.dart';
import '../login_page.dart';
import 'cadastrar_doacao_screen.dart';
import 'buscar_receptor_screen.dart';
import 'integrantes_projeto_screen.dart';
import '../widgets/descricao_screen.dart';
import '../widgets/home_card.dart';

class HomeDoadorScreen extends StatelessWidget {
  const HomeDoadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = const Color(0xFF0A8449);

    return Scaffold(
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagem do projeto
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: const Icon(Icons.home_work_outlined, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        const Text(
                          'Painel do Doador',
                          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    HomeCard(
                      icon: Icons.add,
                      label: 'Cadastrar Doação',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CadastrarDoacaoScreen()),
                      ),
                    ),
                    HomeCard(
                      icon: Icons.search,
                      label: 'Buscar Receptor',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BuscarReceptorScreen()),
                      ),
                    ),
                    HomeCard(
                      icon: Icons.group,
                      label: 'Integrantes do Projeto',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IntegrantesProjetoScreen()),
                      ),
                    ),
                    HomeCard(
                      icon: Icons.info_outline,
                      label: 'Sobre o Projeto',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DescricaoScreen()),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                          icon: const Icon(Icons.logout, size: 20, color: Colors.white),
                          label: const Text(
                            'Sair',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmação'),
                                content: const Text('Deseja realmente sair?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
