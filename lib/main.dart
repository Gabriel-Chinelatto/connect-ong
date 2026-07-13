import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import 'pages/login_page.dart';

import 'doador/main_shell.dart';
import 'doador/perfil_publico_ong_screen.dart';
import 'theme/app_theme.dart';
import 'services/session_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
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

  // Sessão expirada (401 global): qualquer requisição autenticada que receba
  // 401 (token vencido/invalidado) desloga e volta ao login, em vez de deixar
  // a UI presa dando erro. Registrado aqui (uma vez) para o ApiService não
  // depender da camada de sessão/UI diretamente.
  ApiService.onUnauthorized = () async {
    await SessionService().logout();
    ApiService.messengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Sua sessão expirou. Faça login novamente.'),
      ),
    );
    ApiService.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  };

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
          // Permite ARRASTAR listas (inclusive as horizontais) com o mouse/
          // trackpad no desktop e na web — sem isso, os carrosséis não rolam
          // de lado no navegador (só com toque).
          scrollBehavior: const _ArrastarComMouse(),
          // Chaves globais: permitem ao ApiService navegar/avisar quando a
          // sessão expira (401), de fora da árvore de widgets.
          navigatorKey: ApiService.navigatorKey,
          scaffoldMessengerKey: ApiService.messengerKey,
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

/// ScrollBehavior que adiciona o MOUSE (e trackpad/stylus) aos dispositivos de
/// arraste — assim, no desktop e na web, dá para arrastar listas horizontais
/// (carrosséis) com o mouse, além do toque. Mantém o comportamento padrão do
/// Material no resto.
class _ArrastarComMouse extends MaterialScrollBehavior {
  const _ArrastarComMouse();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
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

    // Token vencido/invalidado: há sessão salva, mas o token JWT pode ter
    // expirado desde a última vez. Validamos contra /auth/me ANTES de abrir a
    // home — assim o app não entra na MainShell só para tudo falhar com 401.
    final sessaoOk = await AuthService().sessaoValida();
    if (!mounted) return;
    if (!sessaoOk) {
      await sessionService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
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