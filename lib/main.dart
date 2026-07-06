import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'pages/login_page.dart';

import 'doador/main_shell.dart';
import 'doador/perfil_publico_ong_screen.dart';
import 'theme/app_theme.dart';
import 'services/session_service.dart';
import 'services/api_service.dart';
import 'config/config_controller.dart';
import 'web/portal_institucional_screen.dart';

/// Bootstrap do app: inicializa o binding do Flutter e recarrega o token JWT
/// salvo (via [ApiService.carregarToken]) antes de exibir a UI, para que uma
/// sessão anterior continue autenticada nas chamadas à API.
void main() async {

  // Garante a inicialização do binding antes de acessar plugins (SharedPreferences).
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega o token JWT salvo para reenviá-lo nas requisições autenticadas.
  await ApiService.carregarToken();

  // Carrega a preferência local "Modo Feira" (credenciais demo no login).
  await ConfigController.instance.carregarModoFeira();

  runApp(
    const MyApp(),
  );
}

/// Raiz do app. Aplica o tema da marca e as preferências de acessibilidade
/// (tema claro/escuro, dislexia, alto contraste, escala de fonte) reagindo ao
/// [ConfigController]. Na web abre o portal institucional público; no mobile
/// (app do doador) entra pelo [SplashDecider].
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
            navegacaoSimplificada: config.navegacaoSimplificada,
          ),
          darkTheme: AppTheme.dark(
            dislexia: config.fonteDislexia,
            altoContraste: config.altoContraste,
            navegacaoSimplificada: config.navegacaoSimplificada,
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
          // Na web, a entrada e o portal institucional publico (com suporte a
          // links compartilhados /#/ong/<id>); no mobile (app do doador),
          // segue direto para o fluxo de login/sessao.
          home: kIsWeb ? const EntradaWeb() : const SplashDecider(),
        );
      },
    );
  }
}

/// Entrada da versão WEB: mostra o portal institucional e, se a URL de
/// arranque for um LINK COMPARTILHADO de perfil de ONG (fragmento `/ong/<id>`,
/// como os copiados pelo botão Compartilhar — ver `utils/app_links.dart`),
/// abre o [PerfilPublicoOngScreen] por cima do portal após o primeiro frame.
class EntradaWeb extends StatefulWidget {
  const EntradaWeb({super.key});

  @override
  State<EntradaWeb> createState() => _EntradaWebState();
}

class _EntradaWebState extends State<EntradaWeb> {
  @override
  void initState() {
    super.initState();
    // Navegar só depois do primeiro frame (o Navigator precisa existir).
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirLinkProfundo());
  }

  void _abrirLinkProfundo() {
    if (!mounted) return;
    // Ex.: http://localhost:5100/#/ong/12 → fragment == "/ong/12".
    final m = RegExp(r'^/ong/(\d+)$').firstMatch(Uri.base.fragment);
    if (m == null) return;
    final ongId = int.tryParse(m.group(1)!);
    if (ongId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        // O nome real é carregado pela própria tela (placeholder até lá).
        builder: (_) => PerfilPublicoOngScreen(ongId: ongId, ongNome: 'ONG'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const PortalInstitucionalScreen();
}

/// Decide a rota inicial no mobile: se não há sessão salva, vai para o login;
/// se há, carrega as preferências do usuário e abre a home do doador.
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
        builder: (_) => const MainShell(),
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