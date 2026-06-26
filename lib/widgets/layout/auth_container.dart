import 'package:flutter/material.dart';

/// Cartao branco centralizado e rolavel das telas de autenticacao.
///
/// Padroniza o "card" arredondado com sombra usado como moldura do conteudo
/// (ex.: formulario de login).
class AuthContainer extends StatelessWidget {

  final Widget child;

  const AuthContainer({

    super.key,

    required this.child,
  });

  @override
  Widget build(BuildContext context) {

    return Center(

      child: SingleChildScrollView(

        padding:
            const EdgeInsets.all(24),

        child: Container(

          constraints:
              const BoxConstraints(
            maxWidth: 500,
          ),

          padding:
              const EdgeInsets.all(32),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius:
                BorderRadius.circular(32),

            boxShadow: [

              BoxShadow(

                color:
                    Colors.black.withValues(alpha: 
                  0.08,
                ),

                blurRadius: 30,

                offset:
                    const Offset(0, 10),
              ),
            ],
          ),

          child: child,
        ),
      ),
    );
  }
}