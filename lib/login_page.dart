// lib/login_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'doador/home_doador_screen.dart';
import 'receptor/home_receptor_screen.dart';

import 'services/auth_service.dart';
import 'services/session_service.dart';

import 'models/usuario_logado.dart';

import 'screens/about/descricao_screen.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

const baseColor = Color(0xFF0A8449);

class _LoginPageState
    extends State<LoginPage> {

  final emailController =
      TextEditingController();

  final senhaController =
      TextEditingController();

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

    final email =
        emailController.text.trim();

    final senha =
        senhaController.text;

    if (email.isEmpty || senha.isEmpty) {

      setState(() {

        erroLogin =
            "Preencha todos os campos.";
      });

      return;
    }

    setState(() {

      carregando = true;

      erroLogin = null;
    });

    try {

      final authService =
          AuthService();

      final response =
          await authService.login(

        email: email,

        senha: senha,
      );

      final usuario =
          UsuarioLogado.fromJson(
        response,
      );

      final sessionService =
          SessionService();

      await sessionService.salvarUsuario(
        usuario,
      );

      final tipoUsuario =
          usuario.tipo;

      if (tipoUsuarioSelecionado == 0 &&
          tipoUsuario != 'DOADOR') {

        setState(() {

          erroLogin =
              "Usuário não cadastrado como Doador.";
        });

        return;
      }

      if (tipoUsuarioSelecionado == 1 &&
          tipoUsuario != 'ONG') {

        setState(() {

          erroLogin =
              "Usuário não cadastrado como ONG.";
        });

        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) =>

              tipoUsuarioSelecionado == 0

                  ? const HomeDoadorScreen()

                  : const HomeReceptorScreen(),
        ),
      );

    } catch (e) {

      setState(() {

        erroLogin = e
            .toString()
            .replaceAll(
              'Exception: ',
              '',
            );
      });

    } finally {

      setState(() {

        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    const baseColor =
        Color(0xFF0A8449);

    return Scaffold(

      backgroundColor:
          const Color(0xFFF3F7F5),

      body: SafeArea(

        child: Center(

          child: SingleChildScrollView(

            padding:
                const EdgeInsets.symmetric(
              horizontal: 28,
            ),

            child: Column(

              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                Hero(

                  tag: 'logo_app',

                  child: Container(

                    decoration: BoxDecoration(

                      borderRadius:
                          BorderRadius.circular(35),

                      boxShadow: [

                        BoxShadow(

                          color: Colors.black
                              .withValues(alpha: 0.08),

                          blurRadius: 20,

                          offset:
                              const Offset(0, 10),
                        ),
                      ],
                    ),

                    child: ClipRRect(

                      borderRadius:
                          BorderRadius.circular(35),

                      child: Image.asset(

                        'assets/images/logo.jpg',

                        height: 120,

                        width: 120,

                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(

                  'Connect Ong',

                  style:
                      GoogleFonts.poppins(

                    fontSize: 34,

                    fontWeight:
                        FontWeight.w700,

                    color: baseColor,

                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(

                  'Conectando doadores e ONGs',

                  style:
                      GoogleFonts.poppins(

                    fontSize: 15,

                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 40),

                Container(

                  padding:
                      const EdgeInsets.all(28),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(32),

                    boxShadow: [

                      BoxShadow(

                        color: Colors.black
                            .withValues(alpha: 0.05),

                        blurRadius: 25,

                        offset:
                            const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Column(

                    children: [

                      _buildToggleSelector(
                        baseColor,
                      ),

                      const SizedBox(height: 28),

                      _buildTextField(

                        controller:
                            emailController,

                        label: 'E-mail',

                        icon:
                            Icons.alternate_email,

                        baseColor:
                            baseColor,
                      ),

                      const SizedBox(height: 18),

                      _buildTextField(

                        controller:
                            senhaController,

                        label: 'Senha',

                        icon:
                            Icons.lock_outline,

                        baseColor:
                            baseColor,

                        isPassword: true,
                      ),

                      if (erroLogin != null)
                        _buildErrorBadge(),

                      const SizedBox(height: 28),

                      SizedBox(

                        width: double.infinity,

                        height: 58,

                        child: ElevatedButton(

                          style:
                              ElevatedButton.styleFrom(

                            backgroundColor:
                                baseColor,

                            foregroundColor:
                                Colors.white,

                            elevation: 0,

                            shape:
                                RoundedRectangleBorder(

                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                          ),

                          onPressed:
                              carregando
                                  ? null
                                  : _fazerLogin,

                          child: carregando

                              ? const SizedBox(

                                  height: 24,

                                  width: 24,

                                  child:
                                      CircularProgressIndicator(

                                    color:
                                        Colors.white,

                                    strokeWidth: 2.5,
                                  ),
                                )

                              : Text(

                                  'ENTRAR',

                                  style:
                                      GoogleFonts.poppins(

                                    fontSize: 16,

                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                TextButton(

                  onPressed: () {},

                  child: Text(

                    "Não tem conta? Cadastre-se",

                    style:
                        GoogleFonts.poppins(

                      color:
                          Colors.grey.shade700,

                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),

                TextButton.icon(

                  onPressed: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                            const DescricaoScreen(),
                      ),
                    );
                  },

                  icon: const Icon(
                    Icons.info_outline,
                  ),

                  label: Text(

                    "Sobre o Projeto",

                    style:
                        GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSelector(
    Color baseColor,
  ) {

    return Container(

      padding: const EdgeInsets.all(5),

      decoration: BoxDecoration(

        color: const Color(0xFFF2F2F2),

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Row(

        children: [

          Expanded(

            child: ElevatedButton(

              style:
                  ElevatedButton.styleFrom(

                elevation: 0,

                backgroundColor:
                    tipoUsuarioSelecionado == 0

                        ? baseColor

                        : Colors.transparent,

                foregroundColor:
                    tipoUsuarioSelecionado == 0

                        ? Colors.white

                        : Colors.black87,

                shape:
                    RoundedRectangleBorder(

                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),

              onPressed: () {

                setState(() {

                  tipoUsuarioSelecionado = 0;
                });
              },

              child: Text(

                "Doador",

                style:
                    GoogleFonts.poppins(

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(

            child: ElevatedButton(

              style:
                  ElevatedButton.styleFrom(

                elevation: 0,

                backgroundColor:
                    tipoUsuarioSelecionado == 1

                        ? baseColor

                        : Colors.transparent,

                foregroundColor:
                    tipoUsuarioSelecionado == 1

                        ? Colors.white

                        : Colors.black87,

                shape:
                    RoundedRectangleBorder(

                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),

              onPressed: () {

                setState(() {

                  tipoUsuarioSelecionado = 1;
                });
              },

              child: Text(

                "ONG",

                style:
                    GoogleFonts.poppins(

                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({

    required TextEditingController
        controller,

    required String label,

    required IconData icon,

    required Color baseColor,

    bool isPassword = false,
  }) {

    return TextField(

      controller: controller,

      obscureText: isPassword,

      style: GoogleFonts.poppins(),

      decoration: InputDecoration(

        labelText: label,

        labelStyle:
            GoogleFonts.poppins(),

        filled: true,

        fillColor:
            const Color(0xFFF7F7F7),

        prefixIcon: Icon(

          icon,

          color: baseColor,
        ),

        border: OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(18),

          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(18),

          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(18),

          borderSide: const BorderSide(

            color: Color(0xFF0A8449),

            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBadge() {

    return Container(

      margin:
          const EdgeInsets.only(top: 18),

      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: Colors.red.shade50,

        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Row(

        children: [

          const Icon(

            Icons.error_outline,

            color: Colors.red,
          ),

          const SizedBox(width: 10),

          Expanded(

            child: Text(

              erroLogin!,

              style:
                  GoogleFonts.poppins(

                color: Colors.red.shade700,

                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}