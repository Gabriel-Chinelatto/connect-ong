import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DescricaoScreen
    extends StatelessWidget {

  const DescricaoScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(
        0xFFF3F7F5,
      ),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
            Colors.transparent,

        foregroundColor:
            Colors.black87,

        centerTitle: true,

        title: Text(

          'Sobre o Projeto',

          style:
              GoogleFonts.poppins(

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(

        physics:
            const BouncingScrollPhysics(),

        padding:
            const EdgeInsets.symmetric(

          horizontal: 22,

          vertical: 10,
        ),

        child: Column(

          children: [

            Hero(

              tag: 'logo_app',

              child: Container(

                decoration: BoxDecoration(

                  borderRadius:
                      BorderRadius.circular(
                    32,
                  ),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black
                          .withOpacity(
                        0.10,
                      ),

                      blurRadius: 25,

                      offset:
                          const Offset(
                        0,
                        12,
                      ),
                    ),
                  ],
                ),

                child: ClipRRect(

                  borderRadius:
                      BorderRadius.circular(
                    32,
                  ),

                  child: Image.asset(

                    'assets/images/integrador.jpg',

                    width: 135,

                    height: 135,

                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            Text(

              'Connect Ong',

              style:
                  GoogleFonts.poppins(

                fontSize: 34,

                fontWeight:
                    FontWeight.w700,

                color:
                    const Color(
                  0xFF0A8449,
                ),

                letterSpacing: -1,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(

              'Conectando solidariedade e tecnologia',

              textAlign:
                  TextAlign.center,

              style:
                  GoogleFonts.poppins(

                fontSize: 15,

                color:
                    Colors.black54,
              ),
            ),

            const SizedBox(
              height: 34,
            ),

            _buildModernCard(

              title: 'O Projeto',

              icon:
                  Icons.lightbulb_outline,

              child: Text(

                'O Connect Ong é uma plataforma desenvolvida para aproximar doadores e instituições sociais, promovendo a solidariedade através da tecnologia. O sistema permite cadastrar, gerenciar e localizar doações de forma simples, rápida e intuitiva.',

                textAlign:
                    TextAlign.justify,

                style:
                    GoogleFonts.poppins(

                  fontSize: 15,

                  height: 1.7,

                  color:
                      Colors.black87,
                ),
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            _buildModernCard(

              title: 'Funcionalidades',

              icon:
                  Icons.dashboard_outlined,

              child: Column(

                children: [

                  _buildFeatureItem(
                    'Cadastro de doações',
                  ),

                  _buildFeatureItem(
                    'Busca de receptores',
                  ),

                  _buildFeatureItem(
                    'Gerenciamento de ONGs',
                  ),

                  _buildFeatureItem(
                    'Sistema intuitivo e responsivo',
                  ),

                  _buildFeatureItem(
                    'Interface moderna e acessível',
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            _buildModernCard(

              title:
                  'Equipe de Desenvolvimento',

              icon:
                  Icons.groups_outlined,

              child: Column(

                children: [

                  _buildMemberCard(
                    'Gabriel Chinelatto',
                    'Back-end & Designer',
                  ),

                  _buildMemberCard(
                    'Abner Viola',
                    'Front-end Developer',
                  ),

                  _buildMemberCard(
                    'Luan Felipe',
                    'Back-end Developer',
                  ),

                  _buildMemberCard(
                    'Arthur Souza',
                    'Designer & Tester',
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 36,
            ),

            Container(

              padding:
                  const EdgeInsets.all(
                22,
              ),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  24,
                ),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black
                        .withOpacity(
                      0.04,
                    ),

                    blurRadius: 16,

                    offset:
                        const Offset(
                      0,
                      8,
                    ),
                  ),
                ],
              ),

              child: Column(

                children: [

                  const Icon(

                    Icons.school_outlined,

                    size: 34,

                    color:
                        Color(
                      0xFF0A8449,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Text(

                    'Projeto Integrador',

                    style:
                        GoogleFonts
                            .poppins(

                      fontSize: 18,

                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(

                    'Desenvolvido por alunos do 4°DSN - COTIL',

                    textAlign:
                        TextAlign.center,

                    style:
                        GoogleFonts
                            .poppins(

                      fontSize: 14,

                      color:
                          Colors.black54,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(

                    '2026',

                    style:
                        GoogleFonts
                            .poppins(

                      fontWeight:
                          FontWeight
                              .w600,

                      color:
                          const Color(
                        0xFF0A8449,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard({

    required String title,

    required IconData icon,

    required Widget child,
  }) {

    return Container(

      width: double.infinity,

      padding:
          const EdgeInsets.all(
        24,
      ),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          30,
        ),

        boxShadow: [

          BoxShadow(

            color: Colors.black
                .withOpacity(
              0.05,
            ),

            blurRadius: 18,

            offset:
                const Offset(
              0,
              8,
            ),
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                padding:
                    const EdgeInsets.all(
                  12,
                ),

                decoration:
                    BoxDecoration(

                  color:
                      const Color(
                    0xFF0A8449,
                  ).withOpacity(
                    0.10,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: Icon(

                  icon,

                  color:
                      const Color(
                    0xFF0A8449,
                  ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(

                child: Text(

                  title,

                  style:
                      GoogleFonts
                          .poppins(

                    fontSize: 19,

                    fontWeight:
                        FontWeight
                            .w700,

                    color:
                        const Color(
                      0xFF222222,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          child,
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    String text,
  ) {

    return Padding(

      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(

            margin:
                const EdgeInsets.only(
              top: 4,
            ),

            width: 10,

            height: 10,

            decoration:
                const BoxDecoration(

              color:
                  Color(
                0xFF0A8449,
              ),

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(

            child: Text(

              text,

              style:
                  GoogleFonts.poppins(

                fontSize: 15,

                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(

    String nome,

    String cargo,
  ) {

    return Container(

      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(

        color:
            const Color(
          0xFFF8F8F8,
        ),

        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Row(

        children: [

          Container(

            width: 46,

            height: 46,

            decoration:
                BoxDecoration(

              color:
                  const Color(
                0xFF0A8449,
              ).withOpacity(
                0.12,
              ),

              shape:
                  BoxShape.circle,
            ),

            child: const Icon(

              Icons.person_outline,

              color:
                  Color(
                0xFF0A8449,
              ),
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Text(

                  nome,

                  style:
                      GoogleFonts
                          .poppins(

                    fontWeight:
                        FontWeight
                            .w600,

                    fontSize: 15,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(

                  cargo,

                  style:
                      GoogleFonts
                          .poppins(

                    color:
                        Colors.black54,

                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 