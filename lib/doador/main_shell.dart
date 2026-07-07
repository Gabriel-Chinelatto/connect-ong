import 'package:flutter/material.dart';

import 'dashboard_impacto_screen.dart';
import 'feed_necessidades_screen.dart';
import 'inicio_tab.dart';
import 'meus_matches_screen.dart';
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

class _MainShellState extends State<MainShell> {
  static const double _larguraDesktop = 900;
  static const double _larguraMaxConteudo = 840;

  int _indice = 0;

  // Controller para outras abas pedirem uma sub-aba específica dos Matches
  // (0=Ativas, 1=Aguardando, 2=Concluídas) — ex.: cards do Meu Impacto.
  final MatchesAbaController _abaMatches = MatchesAbaController();

  @override
  void initState() {
    super.initState();
    MainShell.irParaAbaGlobal = _irParaAba;
  }

  @override
  void dispose() {
    if (MainShell.irParaAbaGlobal == _irParaAba) {
      MainShell.irParaAbaGlobal = null;
    }
    _abaMatches.dispose();
    super.dispose();
  }

  /// Troca a aba ativa; [subAbaMatches] (opcional) também posiciona a tela de
  /// Matches na sub-aba pedida.
  void _irParaAba(int aba, [int? subAbaMatches]) {
    if (subAbaMatches != null) _abaMatches.irPara(subAbaMatches);
    setState(() => _indice = aba);
  }

  static const _destinos = [
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Explorar'),
    (Icons.handshake_outlined, Icons.handshake_rounded, 'Matches'),
    (Icons.insights_outlined, Icons.insights_rounded, 'Impacto'),
    (Icons.person_outline, Icons.person_rounded, 'Perfil'),
  ];

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

    final conteudo = IndexedStack(index: _indice, children: abas);
    final largo = MediaQuery.of(context).size.width >= _larguraDesktop;

    if (!largo) {
      return Scaffold(
        body: conteudo,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: _irParaAba,
          destinations: [
            for (final (icone, iconeSel, rotulo) in _destinos)
              NavigationDestination(
                icon: Icon(icone),
                selectedIcon: Icon(iconeSel),
                label: rotulo,
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
              for (final (icone, iconeSel, rotulo) in _destinos)
                NavigationRailDestination(
                  icon: Icon(icone),
                  selectedIcon: Icon(iconeSel),
                  label: Text(rotulo),
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
