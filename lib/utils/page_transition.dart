import 'package:flutter/material.dart';

/// Transicoes de rota reutilizaveis para a navegacao do app.
///
/// Centraliza animacoes de pagina para manter um padrao visual consistente
/// nas trocas de tela.
class PageTransition {

  /// Cria uma rota que combina fade com um leve deslize horizontal,
  /// dando uma entrada suave a [page].

  static Route<T> fade<T>(
    Widget page,
  ) {

    return PageRouteBuilder<T>(

      transitionDuration:
          const Duration(
        milliseconds: 300,
      ),

      reverseTransitionDuration:
          const Duration(
        milliseconds: 250,
      ),

      pageBuilder:
          (
            context,
            animation,
            secondaryAnimation,
          ) {

        return page;
      },

      transitionsBuilder:
          (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {

        final curvedAnimation =
            CurvedAnimation(

          parent: animation,

          curve: Curves.easeInOut,
        );

        return FadeTransition(

          opacity: curvedAnimation,

          child: SlideTransition(

            position:
                Tween<Offset>(

              begin: const Offset(
                0.03,
                0,
              ),

              end: Offset.zero,
            ).animate(curvedAnimation),

            child: child,
          ),
        );
      },
    );
  }
}