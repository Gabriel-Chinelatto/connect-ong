import 'package:flutter/material.dart';

import '../config/config_controller.dart';

/// Transicoes de rota reutilizaveis para a navegacao do app.
///
/// Centraliza animacoes de pagina para manter um padrao visual consistente
/// nas trocas de tela. Quando a NAVEGACAO SIMPLIFICADA esta ligada nas
/// Configuracoes, todas as rotas criadas aqui viram um fade CURTO (~120ms),
/// sem deslocamento — menos movimento para quem prefere/precisa de calma
/// visual.
class PageTransition {

  /// Cria uma rota que combina fade com um leve deslize horizontal,
  /// dando uma entrada suave a [page]. Com navegacao simplificada ligada,
  /// vira apenas um fade curto.
  static Route<T> fade<T>(Widget page) {
    final bool simplificada =
        ConfigController.instance.navegacaoSimplificada;

    return PageRouteBuilder<T>(
      transitionDuration:
          Duration(milliseconds: simplificada ? 120 : 300),
      reverseTransitionDuration:
          Duration(milliseconds: simplificada ? 100 : 250),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        // Navegacao simplificada: so o fade, sem deslize.
        if (simplificada) {
          return FadeTransition(opacity: curvedAnimation, child: child);
        }

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}
