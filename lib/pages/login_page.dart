import 'package:flutter/material.dart';

import '../doador/home_doador_screen.dart';

import '../theme/app_colors.dart';

import '../services/login_service.dart';

import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/inputs/app_text_field.dart';
import '../widgets/layout/auth_container.dart';

import '../utils/page_transition.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  final LoginService _loginService = LoginService();

  bool carregando = false;

  Future<void> fazerLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      carregando = true;
    });

    try {
      // O app mobile e exclusivo do doador (tipoSelecionado 0 = DOADOR).
      await _loginService.fazerLogin(
        email: emailController.text.trim(),
        senha: senhaController.text.trim(),
        tipoSelecionado: 0,
      );

      if (!mounted) return;

      AppSnackbar.sucesso(
        context,
        'Login realizado com sucesso!',
      );

      Navigator.pushReplacement(
        context,
        PageTransition.fade(
          const HomeDoadorScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.erro(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight,
              AppColors.primary,
            ],
          ),
        ),
        child: AuthContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.jpg',
                height: 120,
              ),

              const SizedBox(height: 24),

              const Text(
                'Connect Ong',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Acesso do doador',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 40),

              AppTextField(
                controller: emailController,
                hint: 'E-mail',
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 20),

              AppTextField(
                controller: senhaController,
                hint: 'Senha',
                icon: Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: 32),

              AppButton(
                texto: 'ENTRAR',
                carregando: carregando,
                onPressed: fazerLogin,
              ),

              const SizedBox(height: 28),

              TextButton(
                onPressed: () {},
                child: const Text(
                  'Não tem conta? Cadastre-se',
                ),
              ),

              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
                label: const Text('Sobre o Projeto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
