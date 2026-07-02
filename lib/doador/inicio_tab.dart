import 'package:flutter/material.dart';

import '../models/campanha.dart';
import '../models/necessidade.dart';
import '../models/ranking_ong.dart';
import '../models/usuario_logado.dart';

import '../services/campanha_service.dart';
import '../services/interesse_service.dart';
import '../services/necessidade_service.dart';
import '../services/ranking_service.dart';
import '../services/session_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/categorias.dart';
import '../utils/page_transition.dart';
import '../widgets/notificacao_bell.dart';

import 'buscar_receptor_screen.dart';
import 'campanhas_screen.dart';
import 'favoritos_screen.dart';
import 'minhas_doacoes_screen.dart';
import 'mural_impacto_screen.dart';
import 'ranking_transparencia_screen.dart';
import 'timeline_atividades_screen.dart';

/// Aba INÍCIO do shell do doador — home CURADA (Fase 3).
///
/// Reúne, numa única tela rolável, o que é mais relevante para o doador:
/// saudação + notificações, um resumo do "seu impacto", e carrosséis de
/// campanhas, necessidades urgentes e ONGs em destaque (ranking de
/// transparência). Cada seção falha de forma independente (se uma chamada à API
/// cair, as outras continuam). [onIrParaAba] troca a aba ativa do shell.
class InicioTab extends StatefulWidget {
  final void Function(int aba) onIrParaAba;

  const InicioTab({super.key, required this.onIrParaAba});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  UsuarioLogado? _usuario;
  List<Campanha> _campanhas = [];
  List<Necessidade> _urgentes = [];
  List<RankingOng> _ongsDestaque = [];
  int _matches = 0;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    final user = await SessionService().obterUsuario();

    // Dispara tudo em paralelo; cada seção tem fallback próprio.
    final fCampanhas = _seguro(() => CampanhaService().listarAbertas(), <Campanha>[]);
    final fNecessidades =
        _seguro(() => NecessidadeService().listarAbertas(), <Necessidade>[]);
    final fRanking =
        _seguro(() => RankingService().listar(limite: 8), <RankingOng>[]);
    final fMatches = _contarMatches(user?.id);

    final campanhas = await fCampanhas;
    final necessidades = await fNecessidades;
    final ranking = await fRanking;
    final matches = await fMatches;

    if (!mounted) return;
    setState(() {
      _usuario = user;
      _campanhas = campanhas;
      // "Urgentes": as marcadas como urgente; se não houver, mostra as
      // primeiras abertas para a seção não ficar vazia.
      final urgentes = necessidades.where((n) => n.urgente).toList();
      _urgentes = urgentes.isNotEmpty ? urgentes : necessidades.take(6).toList();
      _ongsDestaque = ranking;
      _matches = matches;
      _carregando = false;
    });
  }

  Future<T> _seguro<T>(Future<T> Function() acao, T fallback) async {
    try {
      return await acao();
    } catch (_) {
      return fallback;
    }
  }

  Future<int> _contarMatches(int? doadorId) async {
    if (doadorId == null) return 0;
    try {
      final lista = await InteresseService().meusMatches(doadorId);
      return lista.where((i) => i.status == 'ACEITO').length;
    } catch (_) {
      return 0;
    }
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
        child: RefreshIndicator(
          onRefresh: _carregarTudo,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
            children: [
              _topo(),
              const SizedBox(height: AppSpacing.lg),
              _cardImpacto(),
              const SizedBox(height: AppSpacing.lg),
              _acessoRapido(),
              const SizedBox(height: AppSpacing.xl),
              if (_carregando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _secaoCampanhas(),
                const SizedBox(height: AppSpacing.xl),
                _secaoUrgentes(),
                const SizedBox(height: AppSpacing.xl),
                _secaoOngs(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---- Topo: saudação + sino de notificações ----
  Widget _topo() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $_primeiroNome 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'Veja onde você pode ajudar hoje.',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const NotificacaoBell(),
      ],
    );
  }

  // ---- Card "seu impacto" ----
  Widget _cardImpacto() {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu impacto',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _matches == 0
                      ? 'Você ainda não tem matches. Que tal começar?'
                      : 'Você já tem $_matches ${_matches == 1 ? "match" : "matches"} com ONGs 💚',
                  style: TextStyle(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => widget.onIrParaAba(3),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  ),
                  child: const Text('Ver meu impacto'),
                ),
              ],
            ),
          ),
          const Icon(Icons.volunteer_activism,
              color: Colors.white24, size: 72),
        ],
      ),
    );
  }

  // ---- Seção: Campanhas (carrossel) ----
  Widget _secaoCampanhas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cabecalho('Campanhas', 'Ver todas',
            () => _abrir(const CampanhasScreen())),
        const SizedBox(height: AppSpacing.md),
        if (_campanhas.isEmpty)
          _vazio('Nenhuma campanha ativa no momento.')
        else
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _campanhas.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _cardCampanha(_campanhas[i]),
            ),
          ),
      ],
    );
  }

  Widget _cardCampanha(Campanha c) {
    final cs = Theme.of(context).colorScheme;
    final double prog = (c.progresso.clamp(0, 100)) / 100;
    return _cartaoBase(
      largura: 264,
      onTap: () => _abrir(const CampanhasScreen()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: cs.onSurface, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            c.ongNome ?? 'ONG',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: AppRadius.brSm,
            child: LinearProgressIndicator(
              value: prog,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'R\$ ${c.valorArrecadado.toStringAsFixed(0)} de R\$ ${c.metaValor.toStringAsFixed(0)}',
            style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ---- Seção: Necessidades urgentes (carrossel) ----
  Widget _secaoUrgentes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cabecalho('Necessidades urgentes', 'Ver todas',
            () => widget.onIrParaAba(1)),
        const SizedBox(height: AppSpacing.md),
        if (_urgentes.isEmpty)
          _vazio('Nenhuma necessidade aberta agora.')
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _urgentes.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _cardUrgente(_urgentes[i]),
            ),
          ),
      ],
    );
  }

  Widget _cardUrgente(Necessidade n) {
    final cs = Theme.of(context).colorScheme;
    return _cartaoBase(
      largura: 230,
      onTap: () => widget.onIrParaAba(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (n.urgente) ...[
                _chip('URGENTE', AppColors.error),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  Categorias.rotulo(n.categoria),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            n.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: cs.onSurface, fontSize: 15),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  n.ongNome ?? 'ONG',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Seção: ONGs em destaque (ranking) ----
  Widget _secaoOngs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cabecalho('ONGs em destaque', 'Ver ranking',
            () => _abrir(const RankingTransparenciaScreen())),
        const SizedBox(height: AppSpacing.md),
        if (_ongsDestaque.isEmpty)
          _vazio('Ranking indisponível no momento.')
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ongsDestaque.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (_, i) => _cardOng(_ongsDestaque[i]),
            ),
          ),
      ],
    );
  }

  Widget _cardOng(RankingOng o) {
    final cs = Theme.of(context).colorScheme;
    return _cartaoBase(
      largura: 210,
      onTap: () => _abrir(const RankingTransparenciaScreen()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _selo(o.nivel),
              const Spacer(),
              if (o.verificada)
                const Icon(Icons.verified, size: 16, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            o.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: cs.onSurface, fontSize: 15),
          ),
          Text(
            o.cidade,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: AppColors.ouro),
              const SizedBox(width: 2),
              Text(
                o.notaMedia.toStringAsFixed(1),
                style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Score ${o.score}',
                  style:
                      TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Componentes reutilizáveis ----
  Widget _cabecalho(String titulo, String acao, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(acao)),
      ],
    );
  }

  Widget _cartaoBase({
    required double largura,
    required Widget child,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: largura,
      child: Material(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _chip(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: AppRadius.brSm,
      ),
      child: Text(
        texto,
        style: TextStyle(
            color: cor, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  // Selo de nível (ouro/prata/bronze) do ranking de transparência.
  Widget _selo(String nivel) {
    final Color cor = switch (nivel.toUpperCase()) {
      'OURO' => AppColors.ouro,
      'PRATA' => AppColors.prata,
      _ => AppColors.bronze,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 13, color: cor),
          const SizedBox(width: 3),
          Text(nivel,
              style: TextStyle(
                  color: cor, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _vazio(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.brLg,
      ),
      child: Text(
        texto,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  // ---- Acesso rapido: atalhos para as demais funcoes (estilo fileira de
  // categorias de apps de marketplace). Absorve o antigo hub em grade.
  Widget _acessoRapido() {
    final atalhos = <(IconData, String, VoidCallback)>[
      (Icons.search, 'Buscar ONGs',
          () => _abrir(const BuscarReceptorScreen())),
      (Icons.volunteer_activism_outlined, 'Minhas doações',
          () => _abrir(const MinhasDoacoesScreen())),
      (Icons.favorite_outline, 'Favoritos',
          () => _abrir(const FavoritosScreen())),
      (Icons.dynamic_feed_outlined, 'Atividades',
          () => _abrir(const TimelineAtividadesScreen())),
      (Icons.public, 'Nosso impacto',
          () => _abrir(const MuralImpactoScreen())),
      (Icons.emoji_events_outlined, 'Ranking',
          () => _abrir(const RankingTransparenciaScreen())),
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: atalhos.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) {
          final (icone, rotulo, acao) = atalhos[i];
          return _atalho(icone, rotulo, acao);
        },
      ),
    );
  }

  Widget _atalho(IconData icone, String rotulo, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brLg,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              rotulo,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _abrir(Widget tela) {
    Navigator.push(context, PageTransition.fade(tela));
  }
}
