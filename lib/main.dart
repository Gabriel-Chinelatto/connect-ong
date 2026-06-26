import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'pages/login_page.dart';

import 'doador/home_doador_screen.dart';
import 'theme/app_theme.dart';
import 'services/session_service.dart';
import 'services/api_service.dart';
import 'config/config_controller.dart';
import 'web/portal_institucional_screen.dart';

void main() async {

  // Garante a inicialização do binding antes de acessar plugins (SharedPreferences).
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega o token JWT salvo para reenviá-lo nas requisições autenticadas.
  await ApiService.carregarToken();

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

    final config = ConfigController.instance;

    return ListenableBuilder(
      listenable: config,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Connect Ong',
          theme: AppTheme.light(
            dislexia: config.fonteDislexia,
            altoContraste: config.altoContraste,
          ),
          darkTheme: AppTheme.dark(
            dislexia: config.fonteDislexia,
            altoContraste: config.altoContraste,
          ),
          themeMode: config.themeMode,
          // Aplica o tamanho da fonte escolhido em todo o app.
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(config.textScale),
              ),
              child: child!,
            );
          },
          // Na web, a entrada e o portal institucional publico; no mobile
          // (app do doador), segue direto para o fluxo de login/sessao.
          home: kIsWeb
              ? const PortalInstitucionalScreen()
              : const SplashDecider(),
        );
      },
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

    // Carrega as preferencias do usuario (tema, fonte, etc.).
    await ConfigController.instance.carregar(usuario.id);
    if (!mounted) return;

    // App mobile e exclusivo do doador.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeDoadorScreen(),
      ),
    );
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