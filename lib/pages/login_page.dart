import 'package:flutter/material.dart';

import '../doador/home_doador_screen.dart';
import '../receptor/home_receptor_screen.dart';

import '../models/usuario_logado.dart';

import '../services/login_service.dart';

import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/inputs/app_text_field.dart';
import '../widgets/layout/auth_container.dart';

import '../utils/page_transition.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({
    super.key,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {

  final emailController =
      TextEditingController();

  final senhaController =
      TextEditingController();

  final LoginService _loginService =
      LoginService();

  bool carregando = false;

  int tipoUsuarioSelecionado = 0;

  Future<void> fazerLogin() async {

    FocusScope.of(context).unfocus();

    setState(() {

      carregando = true;
    });

    try {

      final UsuarioLogado usuario =
          await _loginService.fazerLogin(

        email:
            emailController.text.trim(),

        senha:
            senhaController.text.trim(),

        tipoSelecionado:
            tipoUsuarioSelecionado,
      );

      if (!mounted) return;

      AppSnackbar.sucesso(

        context,

        'Login realizado com sucesso!',
      );

      if (usuario.tipo == 'DOADOR') {

        Navigator.pushReplacement(

          context,

          PageTransition.fade(
            const HomeDoadorScreen(),
          ),
        );

      } else {

        Navigator.pushReplacement(

          context,

          PageTransition.fade(
            const HomeReceptorScreen(),
          ),
        );
      }

    } catch (e) {

      if (!mounted) return;

      AppSnackbar.erro(

        context,

        e.toString().replaceAll(
          'Exception: ',
          '',
        ),
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

              Color(0xFFB7DFC0),

              Color(0xFF2F8F46),
            ],
          ),
        ),

        child: AuthContainer(

          child: Column(

            mainAxisSize:
                MainAxisSize.min,

            children: [

              Image.asset(

                'assets/images/logo.jpg',

                height: 120,
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(

                'Connect Ong',

                style: TextStyle(

                  fontSize: 34,

                  fontWeight:
                      FontWeight.bold,

                  color:
                      Color(0xFF2F8F46),
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              Container(

                decoration: BoxDecoration(

                  color:
                      Colors.grey.shade200,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: Row(

                  children: [

                    Expanded(

                      child: GestureDetector(

                        onTap: () {

                          setState(() {

                            tipoUsuarioSelecionado = 0;
                          });
                        },

                        child: Container(

                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),

                          decoration: BoxDecoration(

                            color:
                                tipoUsuarioSelecionado == 0
                                    ? const Color(0xFF2F8F46)
                                    : Colors.transparent,

                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),

                          child: Text(

                            'Doador',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(

                              color:
                                  tipoUsuarioSelecionado == 0
                                      ? Colors.white
                                      : Colors.black54,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(

                      child: GestureDetector(

                        onTap: () {

                          setState(() {

                            tipoUsuarioSelecionado = 1;
                          });
                        },

                        child: Container(

                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 16,
                          ),

                          decoration: BoxDecoration(

                            color:
                                tipoUsuarioSelecionado == 1
                                    ? const Color(0xFF2F8F46)
                                    : Colors.transparent,

                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),

                          child: Text(

                            'ONG',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(

                              color:
                                  tipoUsuarioSelecionado == 1
                                      ? Colors.white
                                      : Colors.black54,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              AppTextField(

                controller:
                    emailController,

                hint: 'E-mail',

                icon: Icons.email_outlined,
              ),

              const SizedBox(
                height: 20,
              ),

              AppTextField(

                controller:
                    senhaController,

                hint: 'Senha',

                icon: Icons.lock_outline,

                obscureText: true,
              ),

              const SizedBox(
                height: 32,
              ),

              AppButton(

                texto: 'ENTRAR',

                carregando:
                    carregando,

                onPressed: fazerLogin,
              ),

              const SizedBox(
                height: 28,
              ),

              TextButton(

                onPressed: () {},

                child: const Text(

                  'Não tem conta? Cadastre-se',
                ),
              ),

              TextButton.icon(

                onPressed: () {},

                icon: const Icon(
                  Icons.info_outline,
                ),

                label: const Text(
                  'Sobre o Projeto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}