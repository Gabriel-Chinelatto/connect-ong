import 'package:flutter/material.dart';

class PageTransition {

  static Route fade(
    Widget page,
  ) {

    return PageRouteBuilder(

      pageBuilder:
          (_, animation, __) => page,

      transitionsBuilder:

          (_, animation, __, child) {

        return FadeTransition(

          opacity: animation,

          child: child,
        );
      },
    );
  }
}