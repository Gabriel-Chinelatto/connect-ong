import 'package:flutter/material.dart';

import 'dashboard_impacto_screen.dart';
import 'feed_necessidades_screen.dart';
import 'inicio_tab.dart';
import 'meus_matches_screen.dart';
import 'perfil_screen.dart';

/// Shell principal do app do doador: mantém uma barra de navegação inferior
/// FIXA com 5 áreas (Início, Explorar, Matches, Impacto, Perfil). Substitui a
/// antiga home em grade de botões — agora o usuário navega direto entre as
/// áreas sem voltar a um hub.
///
/// Usa [IndexedStack] para preservar o estado de cada aba ao alternar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0;

  void _irParaAba(int aba) {
    setState(() => _indice = aba);
  }

  @override
  Widget build(BuildContext context) {
    // As telas de cada aba. A aba Início recebe um callback para trocar de aba
    // (ex.: atalho "Meus matches" pula direto para a aba 2).
    final abas = <Widget>[
      InicioTab(onIrParaAba: _irParaAba),
      const FeedNecessidadesScreen(),
      const MeusMatchesScreen(),
      const DashboardImpactoScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _indice, children: abas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _irParaAba,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake_rounded),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Impacto',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
