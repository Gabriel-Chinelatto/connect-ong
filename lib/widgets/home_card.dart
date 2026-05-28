import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeCard extends StatelessWidget {

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
  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 18),

      child: Material(

        color: Colors.transparent,

        child: InkWell(

          borderRadius:
              BorderRadius.circular(24),

          onTap: onTap,

          child: Ink(

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(24),

              boxShadow: [

                BoxShadow(

                  color: Colors.black
                      .withOpacity(0.05),

                  blurRadius: 18,

                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Padding(

              padding: const EdgeInsets.symmetric(

                horizontal: 22,
                vertical: 22,
              ),

              child: Row(

                children: [

                  Container(

                    padding:
                        const EdgeInsets.all(14),

                    decoration: BoxDecoration(

                      color: const Color(
                        0xFF0A8449,
                      ).withOpacity(0.12),

                      borderRadius:
                          BorderRadius.circular(18),
                    ),

                    child: Icon(

                      icon,

                      size: 30,

                      color:
                          const Color(0xFF0A8449),
                    ),
                  ),

                  const SizedBox(width: 18),

                  Expanded(

                    child: Text(

                      label,

                      style:
                          GoogleFonts.poppins(

                        fontSize: 17,

                        fontWeight:
                            FontWeight.w600,

                        color:
                            const Color(0xFF222222),
                      ),
                    ),
                  ),

                  Container(

                    padding:
                        const EdgeInsets.all(10),

                    decoration: BoxDecoration(

                      color: Colors.grey
                          .withOpacity(0.08),

                      shape: BoxShape.circle,
                    ),

                    child: const Icon(

                      Icons.arrow_forward_ios,

                      size: 16,

                      color: Colors.black54,
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