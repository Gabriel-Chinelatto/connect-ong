import 'package:flutter/material.dart';

/// Cartao de atalho da Home do doador para uma funcionalidade da plataforma.
///
/// Mostra icone, titulo e seta, com leve animacao de hover, e dispara [onTap]
/// ao ser tocado.
class HomeCard extends StatefulWidget {

  final IconData icon;

  final String label;

  final VoidCallback onTap;

  const HomeCard({

    super.key,

    required this.icon,

    required this.label,

    required this.onTap,
  });

  @override
  State<HomeCard> createState() =>
      _HomeCardState();
}

class _HomeCardState
    extends State<HomeCard> {

  bool hovering = false;

  @override
  Widget build(BuildContext context) {

    return MouseRegion(

      onEnter: (_) {

        setState(() {
          hovering = true;
        });
      },

      onExit: (_) {

        setState(() {
          hovering = false;
        });
      },

      child: AnimatedContainer(

        duration:
            const Duration(
          milliseconds: 200,
        ),

        curve: Curves.easeInOut,

        transform: Matrix4.identity()
          ..scaleByDouble(
            hovering ? 1.02 : 1.0,
            hovering ? 1.02 : 1.0,
            1.0,
            1.0,
          ),

        decoration: BoxDecoration(

          borderRadius:
              BorderRadius.circular(24),

          boxShadow: [

            BoxShadow(

              color: Colors.black.withValues(alpha: 
                hovering ? 0.12 : 0.06,
              ),

              blurRadius:
                  hovering ? 20 : 10,

              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Material(

          color: Colors.white,

          borderRadius:
              BorderRadius.circular(24),

          child: InkWell(

            borderRadius:
                BorderRadius.circular(24),

            onTap: widget.onTap,

            child: Padding(

              padding:
                  const EdgeInsets.all(24),

              child: Row(

                children: [

                  // =========================
                  // ÍCONE
                  // =========================

                  Container(

                    width: 64,

                    height: 64,

                    decoration: BoxDecoration(

                      gradient:
                          const LinearGradient(

                        colors: [

                          Color(0xFF0A8449),

                          Color(0xFF34A853),
                        ],

                        begin:
                            Alignment.topLeft,

                        end:
                            Alignment.bottomRight,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),

                    child: Icon(

                      widget.icon,

                      color: Colors.white,

                      size: 32,
                    ),
                  ),

                  const SizedBox(
                    width: 20,
                  ),

                  // =========================
                  // TEXTO
                  // =========================

                  Expanded(

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        Text(

                          widget.label,

                          style: const TextStyle(

                            fontSize: 20,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(

                          'Acesse esta funcionalidade da plataforma.',

                          style: TextStyle(

                            color:
                                Colors.grey[600],

                            fontSize: 14,

                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =========================
                  // SETA
                  // =========================

                  AnimatedContainer(

                    duration:
                        const Duration(
                      milliseconds: 200,
                    ),

                    transform:
                        Matrix4.identity()
                          ..translateByDouble(
                            hovering ? 4.0 : 0.0,
                            0.0,
                            0.0,
                            1.0,
                          ),

                    child: const Icon(

                      Icons.arrow_forward_ios,

                      size: 20,

                      color: Color(0xFF0A8449),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}