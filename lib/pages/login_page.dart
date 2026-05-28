// lib/login_page.dart

import 'package:flutter/material.dart';

import '../doador/home_doador_screen.dart';
import '../receptor/home_receptor_screen.dart';

import '../services/login_service.dart';

import '../widgets/descricao_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();

  final senhaController = TextEditingController();

  String? erroLogin;

  bool carregando = false;

  int tipoUsuarioSelecionado = 0;

  @override
  void dispose() {
    emailController.dispose();

    senhaController.dispose();

    super.dispose();
  }

  Future<void> _fazerLogin() async {
    final email = emailController.text.trim();

    final senha = senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        erroLogin = 'Preencha todos os campos.';
      });

      return;
    }

    setState(() {
      carregando = true;

      erroLogin = null;
    });

    try {
      final loginService = LoginService();

      final usuario = await loginService.fazerLogin(
        email: email,

        senha: senha,

        tipoSelecionado: tipoUsuarioSelecionado,
      );

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(
          builder:
              (_) =>
                  usuario.tipo == 'DOADOR'
                      ? const HomeDoadorScreen()
                      : const HomeReceptorScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        erroLogin = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF0a8449);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Hero(
                tag: 'logo_app',

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),

                  child: Image.asset(
                    'assets/images/integrador.jpg',

                    height: 150,

                    width: 150,

                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Connect Ong',

                style: TextStyle(
                  fontSize: 32,

                  fontWeight: FontWeight.bold,

                  color: baseColor,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(28),
                ),

                child: Column(
                  children: [
                    _buildToggleSelector(baseColor),

                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: emailController,

                      label: 'E-mail',

                      icon: Icons.alternate_email,

                      baseColor: baseColor,
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: senhaController,

                      label: 'Senha',

                      icon: Icons.lock_outline,

                      baseColor: baseColor,

                      isPassword: true,
                    ),

                    if (erroLogin != null) _buildErrorBadge(),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,

                      height: 55,

                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: baseColor,

                          foregroundColor: Colors.white,
                        ),

                        onPressed: carregando ? null : _fazerLogin,

                        child:
                            carregando
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'ENTRAR',

                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              TextButton(
                onPressed: () {},

                child: Text(
                  "Não tem conta? Cadastre-se",

                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),

              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(builder: (_) => const DescricaoScreen()),
                  );
                },

                icon: const Icon(Icons.info_outline),

                label: const Text("Sobre o Projeto"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSelector(Color baseColor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  tipoUsuarioSelecionado == 0
                      ? baseColor
                      : Colors.grey.shade300,
            ),

            onPressed: () {
              setState(() {
                tipoUsuarioSelecionado = 0;
              });
            },

            child: const Text("Doador"),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  tipoUsuarioSelecionado == 1
                      ? baseColor
                      : Colors.grey.shade300,
            ),

            onPressed: () {
              setState(() {
                tipoUsuarioSelecionado = 1;
              });
            },

            child: const Text("ONG"),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,

    required String label,

    required IconData icon,

    required Color baseColor,

    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,

      obscureText: isPassword,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(icon, color: baseColor),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildErrorBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 16),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.red.shade50,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),

          const SizedBox(width: 8),

          Expanded(
            child: Text(erroLogin!, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
