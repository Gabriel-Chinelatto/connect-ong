import 'package:flutter/material.dart';

import 'pages/login_page.dart';

import 'doador/home_doador_screen.dart';
import 'receptor/home_receptor_screen.dart';
import 'theme/app_theme.dart';
import 'services/session_service.dart';

void main() {

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Connect Ong',

      theme: AppTheme.lightTheme,

      home: const SplashDecider(),
    );
  }
}

class SplashDecider extends StatefulWidget {

  const SplashDecider({
    super.key,
  });

  @override
  State<SplashDecider> createState() =>
      _SplashDeciderState();
}

class _SplashDeciderState
    extends State<SplashDecider> {

  @override
  void initState() {

    super.initState();

    verificarLogin();
  }

  Future<void> verificarLogin() async {

    final sessionService =
        SessionService();

    final usuario =
        await sessionService.obterUsuario();

    if (!mounted) return;

    if (usuario == null) {

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) =>
              const LoginPage(),
        ),
      );

      return;
    }

    if (usuario.tipo == 'DOADOR') {

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) =>
              const HomeDoadorScreen(),
        ),
      );

    } else {

      Navigator.pushReplacement(

        context,

        MaterialPageRoute(

          builder: (_) =>
              const HomeReceptorScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return const Scaffold(

      body: Center(

        child: CircularProgressIndicator(),
      ),
    );
  }
}