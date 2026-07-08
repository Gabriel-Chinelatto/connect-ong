import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/campanha.dart';
import '../models/necessidade.dart';
import '../models/ranking_ong.dart';
import '../models/usuario_logado.dart';

import '../services/campanha_service.dart';
import '../services/interesse_service.dart';
import '../services/necessidade_service.dart';
import '../services/perfil_service.dart';
import '../services/ranking_service.dart';
import '../services/session_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/escala.dart';
import '../utils/frases_home.dart';
import '../utils/page_transition.dart';
import '../widgets/cards/capa_categoria.dart';
import '../widgets/cards/carrossel_campanhas.dart';
import '../widgets/common/chip_foguinho.dart';
import '../widgets/common/dora_avatar.dart';
import '../widgets/notificacao_bell.dart';

import 'assistente_screen.dart';
import 'buscar_receptor_screen.dart';
import 'campanhas_screen.dart';
import 'favoritos_screen.dart';
import 'minhas_doacoes_screen.dart';
import 'mural_impacto_screen.dart';
import 'necessidade_detalhe_screen.dart';
import 'perfil_publico_ong_screen.dart';
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
  Uint8List? _fotoBytes; // foto de perfil (fotoBase64 do backend), se houver
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
    final fFoto = _carregarFoto(user?.id);

    final campanhas = await fCampanhas;
    final necessidades = await fNecessidades;
    final ranking = await fRanking;
    final matches = await fMatches;
    final foto = await fFoto;

    if (!mounted) return;
    setState(() {
      _usuario = user;
      _fotoBytes = foto;
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

  /// Busca a foto de perfil (campo fotoBase64 do GET /usuarios/{id}/perfil).
  /// Qualquer falha (backend antigo, sem foto, rede) degrada para null e o
  /// avatar mostra a inicial do nome.
  Future<Uint8List?> _carregarFoto(int? usuarioId) async {
    if (usuarioId == null) return null;
    try {
      final perfil = await PerfilService().obter(usuarioId);
      final b64 = (perfil['fotoBase64'] ?? '').toString();
      if (b64.isEmpty) return null;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Future<int> _contarMatches(int? doadorId) async {
    if (doadorId == null) return 0;
    try {
      final lista = await InteresseService().meusMatches(doadorId);
      // ACEITO e CONCLUIDO contam como match realizado (mesma regra do
      // dashboard de impacto) — sem o CONCLUIDO, o card zerava assim que
      // a ONG concluía o match.
      return lista
          .where((i) => i.status == 'ACEITO' || i.status == 'CONCLUIDO')
          .length;
    } catch (_) {
      return 0;
    }
  }

  String get _primeiroNome {
    final nome = _usuario?.nome.trim() ?? '';
    if (nome.isEmpty) return 'doador(a)';
    return nome.split(' ').first;
  }

  /// Alturas fixas (carrosseis/atalhos) escaladas junto com o tamanho de
  /// fonte escolhido nas Configurações — evita overflow de pixels quando o
  /// usuário aumenta a fonte.
  double _altura(double base) => base * fatorFonte(context);

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
              const SizedBox(height: AppSpacing.md),
              _barraBusca(),
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

  // ---- Topo: avatar + saudação + frase motivacional + sino ----
  Widget _topo() {
    final cs = Theme.of(context).colorScheme;
    final inicial =
        _primeiroNome.isNotEmpty ? _primeiroNome[0].toUpperCase() : '?';
    return Row(
      children: [
        // Avatar: foto de perfil (fotoBase64) ou inicial em círculo verde.
        Semantics(
          label: 'Foto de perfil',
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            foregroundImage:
                _fotoBytes != null ? MemoryImage(_fotoBytes!) : null,
            child: Text(
              inicial,
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $_primeiroNome 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              // Frase motivacional sorteada a cada entrada no app (estável
              // durante a sessão).
              Text(
                FrasesHome.daSessao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const NotificacaoBell(),
      ],
    );
  }

  // ---- Barra de busca (leva a aba Explorar) + botao da Dora ao LADO (estilo
  // o botao de IA do iFood): quadrado arredondado, na cor da marca, com a
  // mascote como icone. Abre o chat da assistente sem cobrir conteudo. ----
  Widget _barraBusca() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => widget.onIrParaAba(1),
            borderRadius: AppRadius.brXl,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: AppRadius.brXl,
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  // Expanded + ellipsis: o texto encolhe em vez de estourar a
                  // largura quando a fonte é grande (bug real de overflow).
                  Expanded(
                    child: Text(
                      'Buscar necessidades, ONGs, categorias...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _botaoDora(),
      ],
    );
  }

  // Botao redondo da assistente Dora, ao lado da busca. Fundo verde da marca
  // com a mascote em destaque (circulo branco atras para ela aparecer bem).
  Widget _botaoDora() {
    return Semantics(
      button: true,
      label: 'Falar com a Dora, assistente de doacao',
      child: Tooltip(
        message: 'Dora, sua assistente',
        child: Material(
          color: AppColors.primary,
          borderRadius: AppRadius.brXl,
          child: InkWell(
            borderRadius: AppRadius.brXl,
            onTap: () => _abrir(const AssistenteScreen()),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: DoraAvatar(tamanho: 40, fundo: Colors.white),
              ),
            ),
          ),
        ),
      ),
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

  // ---- Seção: Campanhas (carrossel VIVO: auto-avanço 5s + capa + barra
  // animada; ver CarrosselCampanhas) ----
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
          CarrosselCampanhas(
            campanhas: _campanhas,
            altura: _altura(216),
            onTap: (_) => _abrir(const CampanhasScreen()),
          ),
      ],
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
            height: _altura(184),
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

  // Card de necessidade com a CAPA ilustrativa da categoria (gradiente +
  // ícone em marca d'água) e o selo URGENTE sobre a capa.
  Widget _cardUrgente(Necessidade n) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Necessidade ${n.titulo}',
      child: SizedBox(
        width: 230,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // Abre o DETALHE da necessidade (a lista completa continua no
              // "Ver todas" do cabeçalho, que leva à aba Explorar).
              onTap: () => _abrir(NecessidadeDetalheScreen(necessidade: n)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CapaCategoria(
                    categoria: n.categoria,
                    altura: 64,
                    selo: n.urgente ? _seloUrgente() : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              n.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                  fontSize: 15),
                            ),
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
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Selo sólido (fundo vermelho, texto branco) legível SOBRE a capa colorida.
  Widget _seloUrgente() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.brSm,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high, size: 13, color: Colors.white),
          SizedBox(width: 2),
          Text('URGENTE',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
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
            height: _altura(132),
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
      semantica: 'Abrir perfil da ONG ${o.nome}',
      // Abre o PERFIL PÚBLICO da ONG (o ranking continua no "Ver ranking"
      // do cabeçalho da seção).
      onTap: () => _abrir(
          PerfilPublicoOngScreen(ongId: o.ongId, ongNome: o.nome)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _selo(o.nivel),
              // Foguinho 🔥 no card da ONG que é a atual #1 do ranking.
              if (o.diasNoTopo != null) ...[
                const SizedBox(width: 6),
                Flexible(
                    child: ChipFoguinho(dias: o.diasNoTopo!, compacto: true)),
              ],
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
    String? semantica,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semantica,
      child: SizedBox(
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
      height: _altura(98),
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
    // Semantics anuncia como botão para leitores de tela (TalkBack/VoiceOver).
    return Semantics(
      button: true,
      label: rotulo,
      child: Tooltip(
        message: rotulo,
        child: InkWell(
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
        ),
      ),
    );
  }

  void _abrir(Widget tela) {
    Navigator.push(context, PageTransition.fade(tela));
  }
}
