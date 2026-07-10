import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notificacao_service.dart';
import '../services/session_service.dart';
import '../widgets/notificacao_toast.dart';
import 'dashboard_impacto_screen.dart';
import 'feed_necessidades_screen.dart';
import 'inicio_tab.dart';
import 'meus_matches_screen.dart';
import 'notificacoes_screen.dart';
import 'perfil_screen.dart';

/// Shell principal do app do doador com 5 áreas (Início, Explorar, Matches,
/// Impacto, Perfil).
///
/// Navegação ADAPTATIVA: em telas estreitas (celular) usa a barra inferior
/// ([NavigationBar]); em telas largas (desktop/tablet na horizontal, >=
/// [_larguraDesktop]) usa um trilho lateral ([NavigationRail]) e limita a
/// largura do conteúdo para a leitura não "esticar".
///
/// Usa [IndexedStack] para preservar o estado de cada aba ao alternar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Hook GLOBAL para telas empurradas por cima do shell (ex.: Notificações)
  /// pedirem a troca de aba — [aba] do shell e, opcionalmente, a sub-aba dos
  /// Matches (0=Ativas, 1=Aguardando, 2=Concluídas). Fica null quando o shell
  /// não está montado (ex.: portal web antes do login); quem chama deve
  /// tolerar isso (no-op).
  static void Function(int aba, [int? subAbaMatches])? irParaAbaGlobal;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  static const double _larguraDesktop = 900;
  static const double _larguraMaxConteudo = 840;

  int _indice = 0;

  // Anima a TROCA de aba (fade + micro-slide do conteúdo e "pulinho" no ícone
  // selecionado), dando fluidez estilo WhatsApp no lugar do corte seco do
  // IndexedStack. O IndexedStack continua preservando o estado de cada aba.
  late final AnimationController _transicao = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  late final Animation<double> _curva =
      CurvedAnimation(parent: _transicao, curve: Curves.easeOutCubic);

  // Controller para outras abas pedirem uma sub-aba específica dos Matches
  // (0=Ativas, 1=Aguardando, 2=Concluídas) — ex.: cards do Meu Impacto.
  final MatchesAbaController _abaMatches = MatchesAbaController();

  // Polling de notificações: mostra um toast in-app quando chega uma nova
  // (sem depender de push nativo). _ultimoIdNotif guarda a maior id já vista.
  final NotificacaoService _notifService = NotificacaoService();
  final SessionService _sessionService = SessionService();
  Timer? _timerNotif;
  int _ultimoIdNotif = 0;

  @override
  void initState() {
    super.initState();
    MainShell.irParaAbaGlobal = _irParaAba;
    // 1ª leitura define a linha de base (não mostra toast das antigas); depois
    // verifica a cada 20s e avisa só as que chegarem daqui pra frente.
    _pollNotificacoes(inicial: true);
    _timerNotif = Timer.periodic(
        const Duration(seconds: 20), (_) => _pollNotificacoes());
  }

  @override
  void dispose() {
    if (MainShell.irParaAbaGlobal == _irParaAba) {
      MainShell.irParaAbaGlobal = null;
    }
    _timerNotif?.cancel();
    _transicao.dispose();
    _abaMatches.dispose();
    super.dispose();
  }

  Future<void> _pollNotificacoes({bool inicial = false}) async {
    final u = await _sessionService.obterUsuario();
    if (u == null) return;
    try {
      final lista = await _notifService.listar(u.id);
      if (lista.isEmpty) return;
      final maxId =
          lista.map((n) => n.id).reduce((a, b) => a > b ? a : b);
      if (inicial) {
        _ultimoIdNotif = maxId; // linha de base, sem avisar as antigas
        return;
      }
      final novas = lista.where((n) => n.id > _ultimoIdNotif).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      _ultimoIdNotif = maxId;
      if (novas.isEmpty || !mounted) return;
      // Evita uma enxurrada: no máximo 3 toasts por ciclo.
      for (final n in novas.length > 3 ? novas.sublist(novas.length - 3) : novas) {
        mostrarNotificacaoToast(context, n, onTap: _abrirNotificacoes);
      }
    } catch (_) {
      // rede instável: tenta de novo no próximo ciclo.
    }
  }

  void _abrirNotificacoes() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
    );
  }

  /// Troca a aba ativa; [subAbaMatches] (opcional) também posiciona a tela de
  /// Matches na sub-aba pedida. Ao mudar de aba, dispara a animação de transição
  /// e um leve feedback tátil (sensação premium, estilo apps nativos).
  void _irParaAba(int aba, [int? subAbaMatches]) {
    if (subAbaMatches != null) _abaMatches.irPara(subAbaMatches);
    final mudou = aba != _indice;
    setState(() => _indice = aba);
    if (mudou) {
      HapticFeedback.selectionClick();
      _transicao.forward(from: 0);
    }
  }

  static const _destinos = [
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Explorar'),
    (Icons.handshake_outlined, Icons.handshake_rounded, 'Matches'),
    (Icons.insights_outlined, Icons.insights_rounded, 'Impacto'),
    (Icons.person_outline, Icons.person_rounded, 'Perfil'),
  ];

  // Envolve o conteúdo da aba num fade + micro-slide de entrada, tocado a cada
  // troca de aba (o controller vai de 0→1). Fora da troca fica estático (value=1).
  Widget _conteudoAnimado(Widget filho) {
    return AnimatedBuilder(
      animation: _curva,
      builder: (context, child) {
        final t = _curva.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
      child: filho,
    );
  }

  // Ícone da aba SELECIONADA (versão "cheia") com um leve "pulinho" de escala
  // quando ela acabou de ser escolhida — só a aba ativa anima.
  Widget _iconeSelecionado(IconData icone, int indice) {
    if (indice != _indice) return Icon(icone);
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1)
          .animate(CurvedAnimation(parent: _transicao, curve: Curves.easeOutBack)),
      child: Icon(icone),
    );
  }

  @override
  Widget build(BuildContext context) {
    // As telas de cada aba. A aba Início recebe um callback para trocar de aba
    // (ex.: atalho "Ver meu impacto" pula direto para a aba 3).
    final abas = <Widget>[
      InicioTab(onIrParaAba: _irParaAba),
      FeedNecessidadesScreen(ativa: _indice == 1),
      MeusMatchesScreen(abaController: _abaMatches, ativa: _indice == 2),
      DashboardImpactoScreen(onIrParaAba: _irParaAba),
      const PerfilScreen(),
    ];

    // IndexedStack preserva o estado de todas as abas; o wrapper animado só
    // dá o fade + micro-slide de entrada na aba recém-selecionada.
    final conteudo = _conteudoAnimado(
      IndexedStack(index: _indice, children: abas),
    );
    final largo = MediaQuery.of(context).size.width >= _larguraDesktop;

    if (!largo) {
      return Scaffold(
        body: conteudo,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: _irParaAba,
          destinations: [
            for (final (indice, dest) in _destinos.indexed)
              NavigationDestination(
                icon: Icon(dest.$1),
                selectedIcon: _iconeSelecionado(dest.$2, indice),
                label: dest.$3,
              ),
          ],
        ),
      );
    }

    // Layout desktop: trilho lateral + conteúdo centralizado com largura máxima.
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _indice,
            onDestinationSelected: _irParaAba,
            labelType: NavigationRailLabelType.all,
            backgroundColor: cs.surface,
            destinations: [
              for (final (indice, dest) in _destinos.indexed)
                NavigationRailDestination(
                  icon: Icon(dest.$1),
                  selectedIcon: _iconeSelecionado(dest.$2, indice),
                  label: Text(dest.$3),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: cs.outlineVariant),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: _larguraMaxConteudo),
                child: conteudo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
