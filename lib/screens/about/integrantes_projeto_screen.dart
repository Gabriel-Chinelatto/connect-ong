import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntegrantesProjetoScreen
    extends StatelessWidget {

  const IntegrantesProjetoScreen({
    super.key,
  });

  

  final List<Map<String, String>>
      integrantes = const [

    {

      'nome':
          'Gabriel Chinelatto',

      'descricao':
          'Aluno do 4°DSN, Desenvolvedor Back-end e Designer',

      'foto':
          'assets/images/gabriel.jpg',
    },

    {

      'nome':
          'Arthur Souza',

      'descricao':
          'Aluno do 4°DSN, Designer e Tester',

      'foto':
          'assets/images/arthur.jpg',
    },

    {

      'nome':
          'Luan Felipe',

      'descricao':
          'Aluno do 4°DSN, Desenvolvedor Back-end e Designer',

      'foto':
          'assets/images/luan.png',
    },

    {

      'nome':
          'Abner Viola',

      'descricao':
          'Aluno do 4°DSN e Desenvolvedor Front-end',

      'foto':
          'assets/images/abner.jpg',
    }
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF3F7F5),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
            Colors.transparent,

        foregroundColor:
            Colors.black87,

        centerTitle: true,

        title: Text(

          'Integrantes do Projeto',

          style:
              GoogleFonts.poppins(

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      body: ListView.builder(

        physics:
            const BouncingScrollPhysics(),

        padding:
            const EdgeInsets.all(20),

        itemCount:
            integrantes.length,

        itemBuilder:
            (context, i) {

          final integrante =
              integrantes[i];

          return Container(

            margin:
                const EdgeInsets.only(
              bottom: 22,
            ),

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(
                28,
              ),

              boxShadow: [

                BoxShadow(

                  color: Colors.black
                      .withValues(alpha: 
                    0.05,
                  ),

                  blurRadius: 20,

                  offset:
                      const Offset(
                    0,
                    8,
                  ),
                ),
              ],
            ),

            child: Padding(

              padding:
                  const EdgeInsets.all(
                20,
              ),

              child: Row(

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Container(

                    decoration:
                        BoxDecoration(

                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),

                      boxShadow: [

                        BoxShadow(

                          color: Colors
                              .black
                              .withValues(alpha: 
                            0.10,
                          ),

                          blurRadius:
                              12,

                          offset:
                              const Offset(
                            0,
                            6,
                          ),
                        ),
                      ],
                    ),

                    child: ClipRRect(

                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),

                      child: Image.asset(

                        integrante[
                            'foto']!,

                        width: 82,

                        height: 82,

                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 18,
                  ),

                  Expanded(

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Row(

                          children: [

                            Container(

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
                              width: 8,
                            ),

                            Expanded(

                              child: Text(

                                integrante[
                                    'nome']!,

                                style:
                                    GoogleFonts
                                        .poppins(

                                  fontSize:
                                      18,

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
                          height: 12,
                        ),

                        Container(

                          padding:
                              const EdgeInsets.symmetric(

                            horizontal:
                                12,

                            vertical:
                                8,
                          ),

                          decoration:
                              BoxDecoration(

                            color:
                                const Color(
                              0xFF0A8449,
                            ).withValues(alpha: 
                              0.10,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),

                          child: Text(

                            integrante[
                                'descricao']!,

                            style:
                                GoogleFonts
                                    .poppins(

                              fontSize:
                                  14,

                              height:
                                  1.5,

                              color:
                                  const Color(
                                0xFF066537,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}