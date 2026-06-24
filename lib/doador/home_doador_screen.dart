import 'package:flutter/material.dart';

import '../pages/login_page.dart';

import '../screens/about/descricao_screen.dart';
import '../screens/about/integrantes_projeto_screen.dart';

import '../services/session_service.dart';

import '../utils/page_transition.dart';

import '../widgets/cards/home_card.dart';

import 'minhas_doacoes_screen.dart';
import 'buscar_receptor_screen.dart';
import 'feed_necessidades_screen.dart';
import 'meus_matches_screen.dart';
import 'dashboard_impacto_screen.dart';
import 'configuracoes_screen.dart';
import '../config/config_controller.dart';
import '../widgets/common/app_footer.dart';

class HomeDoadorScreen extends StatelessWidget {

  const HomeDoadorScreen({
    super.key,
  });

  Future<void> _logout(
    BuildContext context,
  ) async {

    final sessionService =
        SessionService();

    await sessionService.logout();

    ConfigController.instance.limpar();

    if (!context.mounted) return;

    Navigator.pushReplacement(

      context,

      PageTransition.fade(

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

                    // HEADER

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

                                              Icons.favorite,

                                              color: Colors.white,

                                              size: 18,
                                            ),

                                            SizedBox(
                                              width: 8,
                                            ),

                                            Text(

                                              'Painel do Doador',

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

                                        'Conectando pessoas através da solidariedade.',

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

                                        'Acompanhe projetos sociais, encontre ONGs e participe de iniciativas que geram impacto real na sociedade.',

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

                                              'Plataforma acadêmica focada em transparência e impacto social.',

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

                                  'Painel do Doador',

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

                                  'Conectando doadores e ONGs através da solidariedade.',

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

                      'Escolha uma funcionalidade para continuar navegando pela plataforma.',

                      style: TextStyle(

                        color: Colors.white
                            .withValues(alpha: 0.9),

                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      height: 40,
                    ),

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
                          icon: Icons.favorite_outline,
                          label: 'Necessidades',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition.fade(
                                const FeedNecessidadesScreen(),
                              ),
                            );
                          },
                        ),

                        HomeCard(
                          icon: Icons.handshake_outlined,
                          label: 'Meus Matches',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition.fade(
                                const MeusMatchesScreen(),
                              ),
                            );
                          },
                        ),

                        HomeCard(
                          icon: Icons.insights_outlined,
                          label: 'Meu Impacto',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition.fade(
                                const DashboardImpactoScreen(),
                              ),
                            );
                          },
                        ),

                        HomeCard(
                          icon: Icons.settings_outlined,
                          label: 'Configurações',
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition.fade(
                                const ConfiguracoesScreen(),
                              ),
                            );
                          },
                        ),

                        HomeCard(

                          icon: Icons.add_circle_outline,
                          label: 'Minhas Doações',
                          onTap: () {
                           Navigator.push(
                            context,
                   PageTransition.fade(
                          const MinhasDoacoesScreen(),
                              ),
                            );
                          },
                        ),

                        HomeCard(

                          icon:
                              Icons.search,

                          label:
                              'Buscar Receptor',

                          onTap: () {

                            Navigator.push(

                              context,

                              PageTransition.fade(

                                const BuscarReceptorScreen(),
                              ),
                            );
                          },
                        ),

                        HomeCard(

                          icon:
                              Icons.groups_rounded,

                          label:
                              'Integrantes do Projeto',

                          onTap: () {

                            Navigator.push(

                              context,

                              PageTransition.fade(

                                const IntegrantesProjetoScreen(),
                              ),
                            );
                          },
                        ),

                        HomeCard(

                          icon:
                              Icons.info_outline_rounded,

                          label:
                              'Sobre o Projeto',

                          onTap: () {

                            Navigator.push(

                              context,

                              PageTransition.fade(

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