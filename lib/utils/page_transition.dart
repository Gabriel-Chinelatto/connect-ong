import 'package:flutter/material.dart';

class PageTransition {

  static Route fade(
    Widget page,
  ) {

    return PageRouteBuilder(

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