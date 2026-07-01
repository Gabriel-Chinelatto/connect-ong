import 'package:flutter/material.dart';

import '../models/usuario_logado.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/page_transition.dart';

import 'campanhas_screen.dart';
import 'conquistas_screen.dart';
import 'home_doador_screen.dart';
import 'ranking_transparencia_screen.dart';

/// Aba INÍCIO do shell do doador.
///
/// Versão de transição (Fase 1): saudação personalizada + atalhos para as
/// principais áreas, mantendo acesso a TODAS as funções via "Ver todas as
/// funções". Será substituída pela home curada (carrossel de campanhas,
/// necessidades urgentes, ONGs em destaque) na Fase 3.
///
/// [onIrParaAba] troca a aba ativa do shell (ex.: pular direto para Matches).
class InicioTab extends StatefulWidget {
  final void Function(int aba) onIrParaAba;

  const InicioTab({super.key, required this.onIrParaAba});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  UsuarioLogado? _usuario;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final u = await SessionService().obterUsuario();
    if (!mounted) return;
    setState(() => _usuario = u);
  }

  String get _primeiroNome {
    final nome = _usuario?.nome.trim() ?? '';
    if (nome.isEmpty) return 'doador(a)';
    return nome.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _saudacao(),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Atalhos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _grelhaAtalhos(),
            const SizedBox(height: AppSpacing.xl),
            _botaoTodasFuncoes(),
          ],
        ),
      ),
    );
  }

  // Cartão de boas-vindas com o verde da marca.
  Widget _saudacao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: AppRadius.brXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $_primeiroNome 👋',
            style: const TextStyle(
              color: AppColors.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Conecte-se a quem precisa e acompanhe o impacto das suas doações.',
            style: TextStyle(
              color: AppColors.onPrimary.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grelhaAtalhos() {
    final atalhos = <_Atalho>[
      _Atalho(Icons.favorite_outline, 'Necessidades',
          () => widget.onIrParaAba(1)),
      _Atalho(Icons.handshake_outlined, 'Meus matches',
          () => widget.onIrParaAba(2)),
      _Atalho(Icons.insights_outlined, 'Meu impacto',
          () => widget.onIrParaAba(3)),
      _Atalho(Icons.campaign_outlined, 'Campanhas',
          () => _abrir(const CampanhasScreen())),
      _Atalho(Icons.emoji_events_outlined, 'Ranking',
          () => _abrir(const RankingTransparenciaScreen())),
      _Atalho(Icons.workspace_premium_outlined, 'Conquistas',
          () => _abrir(const ConquistasScreen())),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.7,
      children: atalhos.map(_cardAtalho).toList(),
    );
  }

  Widget _cardAtalho(_Atalho a) {
    // Cores do TEMA (reagem a claro/escuro) em vez de constantes fixas — assim
    // o card fica legivel nos dois modos.
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: a.onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(a.icone, color: AppColors.primary),
              ),
              Text(
                a.rotulo,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoTodasFuncoes() {
    return OutlinedButton.icon(
      onPressed: () => _abrir(const HomeDoadorScreen()),
      icon: const Icon(Icons.apps),
      label: const Text('Ver todas as funções'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      ),
    );
  }

  void _abrir(Widget tela) {
    Navigator.push(context, PageTransition.fade(tela));
  }
}

class _Atalho {
  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;
  _Atalho(this.icone, this.rotulo, this.onTap);
}
