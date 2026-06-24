import 'package:flutter/material.dart';

import '../pages/login_page.dart';

import '../screens/about/descricao_screen.dart';

import '../services/session_service.dart';

import '../widgets/cards/home_card.dart';

import '../widgets/common/app_footer.dart';

class HomeReceptorScreen extends StatelessWidget {

  const HomeReceptorScreen({
    super.key,
  });

  Future<void> _logout(
    BuildContext context,
  ) async {

    final sessionService =
        SessionService();

    await sessionService.logout();

    if (!context.mounted) return;

    Navigator.pushReplacement(

      context,

      MaterialPageRoute(

        builder: (_) =>
            const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final larguraTela =
        MediaQuery.of(context).size.width;

    final bool web =
        larguraTela > 900;

    return Scaffold(

      body: Container(

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

            colors: [

              Color(0xFFA8DBC1),

              Color(0xFF0A8449),
            ],
          ),
        ),

        child: SafeArea(

          child: Center(

            child: ConstrainedBox(

              constraints:
                  const BoxConstraints(
                maxWidth: 1200,
              ),

              child: SingleChildScrollView(

                padding:
                    const EdgeInsets.symmetric(

                  horizontal: 24,

                  vertical: 32,
                ),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // =========================
                    // HERO HEADER
                    // =========================

                    Container(

                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(32),

                      decoration: BoxDecoration(

                        color: Colors.white
                            .withValues(alpha: 0.15),

                        borderRadius:
                            BorderRadius.circular(
                          32,
                        ),

                        border: Border.all(

                          color: Colors.white
                              .withValues(alpha: 0.15),
                        ),
                      ),

                      child: web

                          // =========================
                          // WEB
                          // =========================

                          ? Row(

                              children: [

                                Expanded(

                                  flex: 2,

                                  child: Column(

                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [

                                      Container(

                                        padding:
                                            const EdgeInsets.symmetric(

                                          horizontal: 14,

                                          vertical: 8,
                                        ),

                                        decoration: BoxDecoration(

                                          color: Colors.white
                                              .withValues(alpha: 0.18),

                                          borderRadius:
                                              BorderRadius.circular(
                                            30,
                                          ),
                                        ),

                                        child: const Row(

                                          mainAxisSize:
                                              MainAxisSize.min,

                                          children: [

                                            Icon(

                                              Icons.volunteer_activism,

                                              color: Colors.white,

                                              size: 18,
                                            ),

                                            SizedBox(
                                              width: 8,
                                            ),

                                            Text(

                                              'Painel da ONG',

                                              style: TextStyle(

                                                color: Colors.white,

                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 24,
                                      ),

                                      const Text(

                                        'Gerencie sua ONG de forma simples e transparente.',

                                        style: TextStyle(

                                          color: Colors.white,

                                          fontSize: 38,

                                          fontWeight:
                                              FontWeight.bold,

                                          height: 1.2,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 16,
                                      ),

                                      Text(

                                        'Cadastre necessidades, acompanhe doações e fortaleça o impacto social da sua instituição.',

                                        style: TextStyle(

                                          color: Colors.white
                                              .withValues(alpha: 0.9),

                                          fontSize: 17,

                                          height: 1.6,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 28,
                                      ),

                                      Container(

                                        padding:
                                            const EdgeInsets.symmetric(

                                          horizontal: 18,

                                          vertical: 14,
                                        ),

                                        decoration: BoxDecoration(

                                          color: Colors.white
                                              .withValues(alpha: 0.14),

                                          borderRadius:
                                              BorderRadius.circular(
                                            20,
                                          ),
                                        ),

                                        child: const Row(

                                          mainAxisSize:
                                              MainAxisSize.min,

                                          children: [

                                            Icon(

                                              Icons.verified,

                                              color: Colors.white,
                                            ),

                                            SizedBox(
                                              width: 12,
                                            ),

                                            Text(

                                              'Sistema acadêmico focado em organização e transparência.',

                                              style: TextStyle(

                                                color: Colors.white,

                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                  width: 40,
                                ),

                                Expanded(

                                  child: Center(

                                    child: Container(

                                      padding:
                                          const EdgeInsets.all(24),

                                      decoration: BoxDecoration(

                                        color: Colors.white,

                                        borderRadius:
                                            BorderRadius.circular(
                                          32,
                                        ),

                                        boxShadow: [

                                          BoxShadow(

                                            color: Colors.black
                                                .withValues(alpha: 0.12),

                                            blurRadius: 24,

                                            offset:
                                                const Offset(0, 10),
                                          ),
                                        ],
                                      ),

                                      child: Image.asset(

                                        'assets/images/logo.jpg',

                                        height: 160,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )

                          // =========================
                          // MOBILE
                          // =========================

                          : Column(

                              children: [

                                Container(

                                  padding:
                                      const EdgeInsets.all(18),

                                  decoration: BoxDecoration(

                                    color: Colors.white,

                                    borderRadius:
                                        BorderRadius.circular(
                                      28,
                                    ),
                                  ),

                                  child: Image.asset(

                                    'assets/images/logo.jpg',

                                    height: 90,
                                  ),
                                ),

                                const SizedBox(
                                  height: 24,
                                ),

                                const Text(

                                  'Painel da ONG',

                                  textAlign: TextAlign.center,

                                  style: TextStyle(

                                    color: Colors.white,

                                    fontSize: 32,

                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 16,
                                ),

                                Text(

                                  'Conectando instituições e doadores através da solidariedade.',

                                  textAlign: TextAlign.center,

                                  style: TextStyle(

                                    color: Colors.white
                                        .withValues(alpha: 0.9),

                                    fontSize: 16,

                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(
                      height: 48,
                    ),

                    // =========================
                    // TÍTULO
                    // =========================

                    const Text(

                      'Ações disponíveis',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 28,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(

                      'Escolha uma funcionalidade para continuar utilizando a plataforma.',

                      style: TextStyle(

                        color: Colors.white
                            .withValues(alpha: 0.9),

                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      height: 40,
                    ),

                    // =========================
                    // CARDS
                    // =========================

                    GridView.count(

                      shrinkWrap: true,

                      physics:
                          const NeverScrollableScrollPhysics(),

                      crossAxisCount:
                          web ? 2 : 1,

                      crossAxisSpacing: 24,

                      mainAxisSpacing: 28,

                      childAspectRatio:
                          web ? 2.4 : 2.0,

                      children: [

                        HomeCard(

                          icon:
                              Icons.add_business_outlined,

                          label:
                              'Cadastrar ONG',

                          onTap: () {},
                        ),

                        HomeCard(

                          icon:
                              Icons.edit_outlined,

                          label:
                              'Editar Perfil da ONG',

                          onTap: () {},
                        ),

                        HomeCard(

                          icon:
                              Icons.volunteer_activism,

                          label:
                              'Gerenciar Pedidos',

                          onTap: () {},
                        ),

                        HomeCard(

                          icon:
                              Icons.info_outline_rounded,

                          label:
                              'Sobre o Projeto',

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
                      ],
                    ),

                    const SizedBox(
                      height: 48,
                    ),

                    // =========================
                    // LOGOUT
                    // =========================

                    Center(

                      child: OutlinedButton.icon(

                        onPressed: () =>
                            _logout(context),

                        icon: const Icon(
                          Icons.logout,
                        ),

                        label: const Text(
                          'Sair',
                        ),

                        style:
                            OutlinedButton.styleFrom(

                          foregroundColor:
                              Colors.white,

                          side: const BorderSide(

                            color: Colors.white,
                          ),

                          padding:
                              const EdgeInsets.symmetric(

                            horizontal: 28,

                            vertical: 16,
                          ),

                          shape: RoundedRectangleBorder(

                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                       height: 24,
                        ),

                        const AppFooter(),

                          const SizedBox(
                       height: 12,
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