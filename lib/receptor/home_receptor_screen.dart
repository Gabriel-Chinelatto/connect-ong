import 'package:flutter/material.dart';

import '../pages/login_page.dart';

import '../services/session_service.dart';

import 'buscar_ong_screen.dart';
import 'cadastrar_ong_screen.dart';

import '../widgets/integrantes_projeto_screen.dart';
import '../widgets/descricao_screen.dart';
import '../widgets/home_card.dart';

class HomeReceptorScreen extends StatelessWidget {

  const HomeReceptorScreen({
    super.key,
  });

  Future<void> logout(
    BuildContext context,
  ) async {

    final confirm = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text(
          'Confirmação',
        ),

        content: const Text(
          'Deseja realmente sair?',
        ),

        actions: [

          TextButton(

            onPressed: () {

              Navigator.of(context).pop(false);
            },

            child: const Text(
              'Cancelar',
            ),
          ),

          TextButton(

            onPressed: () {

              Navigator.of(context).pop(true);
            },

            child: const Text(
              'OK',
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final sessionService =
        SessionService();

    await sessionService.logout();

    Navigator.of(context).pushAndRemoveUntil(

      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),

      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            colors: [
              Color(0xFFA8DBC1),
              Color(0xFF0A8449),
            ],

            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(

          child: Padding(

            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),

            child: SingleChildScrollView(

              child: IntrinsicHeight(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,

                  children: [

                    Center(

                      child: Container(

                        decoration: BoxDecoration(

                          borderRadius:
                              BorderRadius.circular(20),

                          boxShadow: [

                            BoxShadow(

                              color: Colors.black
                                  .withOpacity(0.15),

                              blurRadius: 10,

                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),

                        child: ClipRRect(

                          borderRadius:
                              BorderRadius.circular(20),

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

                          backgroundColor:
                              Colors.white.withOpacity(0.3),

                          child: const Icon(

                            Icons.home_work_outlined,

                            size: 40,

                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(

                          child: Text(

                            'Bem-vindo, Usuário(a)!',

                            style: TextStyle(

                              fontSize: 28,

                              fontWeight:
                                  FontWeight.bold,

                              color: Colors.white
                                  .withOpacity(0.95),

                              shadows: const [

                                Shadow(

                                  color: Colors.black45,

                                  blurRadius: 6,

                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(

                      'Aqui você pode:',

                      style: TextStyle(

                        fontSize: 22,

                        fontWeight: FontWeight.bold,

                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 20),

                    HomeCard(

                      icon: Icons.add,

                      label: 'Cadastrar ONG',

                      onTap: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) =>
                                const CadastrarOngScreen(),
                          ),
                        );
                      },
                    ),

                    HomeCard(

                      icon: Icons.search,

                      label: 'Buscar ONG',

                      onTap: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) =>
                                const BuscarOngScreen(),
                          ),
                        );
                      },
                    ),

                    HomeCard(

                      icon: Icons.group,

                      label: 'Integrantes do Projeto',

                      onTap: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) =>
                                const IntegrantesProjetoScreen(),
                          ),
                        );
                      },
                    ),

                    HomeCard(

                      icon: Icons.info_outline,

                      label: 'Sobre o Projeto',

                      onTap: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) =>
                                const DescricaoScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    Padding(

                      padding:
                          const EdgeInsets.only(bottom: 16),

                      child: Center(

                        child: OutlinedButton.icon(

                          style:
                              OutlinedButton.styleFrom(

                            foregroundColor:
                                Colors.white,

                            side: const BorderSide(
                              color: Colors.white,
                            ),

                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),

                            shape:
                                RoundedRectangleBorder(

                              borderRadius:
                                  BorderRadius.circular(24),
                            ),

                            backgroundColor:
                                Colors.transparent,
                          ),

                          icon: const Icon(

                            Icons.logout,

                            size: 20,

                            color: Colors.white,
                          ),

                          label: const Text(

                            'Sair',

                            style: TextStyle(

                              color: Colors.white,

                              fontWeight:
                                  FontWeight.w600,

                              fontSize: 15,
                            ),
                          ),

                          onPressed: () {

                            logout(context);
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