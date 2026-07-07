import 'dart:async';

import 'package:flutter/material.dart';

import '../config/config_controller.dart';
import '../models/necessidade.dart';
import '../services/api_service.dart';
import '../services/necessidade_service.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/categorias.dart';
import '../utils/escala.dart';
import '../utils/page_transition.dart';
import '../utils/tempo.dart';
import '../widgets/cards/capa_categoria.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/empty_state.dart';

import 'necessidade_detalhe_screen.dart';
import 'perfil_publico_ong_screen.dart';

/// Feed das necessidades abertas das ONGs (aba Explorar), com filtros (busca,
/// categoria, urgentes) e priorizacao. Hero feature: ao demonstrar interesse
/// numa necessidade, cria um interesse que a ONG pode aceitar (match),
/// habilitando o chat.
///
/// AUTO-ATUALIZAÇÃO: enquanto a aba está visível ([ativa]), recarrega ao
/// voltar o foco e por um polling leve (silencioso, sem spinner nem apagar a
/// lista em falha) — necessidades novas aparecem sem refresh manual. Com
/// navegação simplificada o intervalo é bem maior (menos rede/movimento).
///
/// Redesenho (Bloco 21 / Fase 4): consome o design system e usa cores do TEMA
/// (colorScheme), ficando correto no claro e no escuro.
class FeedNecessidadesScreen extends StatefulWidget {
  /// true quando esta é a aba VISÍVEL do shell. Controla o polling em tempo
  /// real: só atualiza sozinho enquanto o usuário está de fato nesta aba
  /// (evita bater na API com a tela escondida no IndexedStack). Padrão true
  /// para telas isoladas (harness/testes).
  final bool ativa;

  const FeedNecessidadesScreen({super.key, this.ativa = true});

  @override
  State<FeedNecessidadesScreen> createState() => _FeedNecessidadesScreenState();
}

class _FeedNecessidadesScreenState extends State<FeedNecessidadesScreen>
    with WidgetsBindingObserver {
  final NecessidadeService _necessidadeService = NecessidadeService();
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  List<Necessidade> _necessidades = [];

  /// Necessidades cujo interesse do doador está EM ANDAMENTO (último interesse
  /// PENDENTE ou ACEITO). Só estas exibem "Interesse demonstrado" (desabilitado)
  /// e vão para o fim da lista. Semeado do servidor a cada carga.
  final Set<int> _emAndamento = {};

  /// Necessidades em que o doador já teve um interesse CONCLUÍDO e nenhum em
  /// andamento — ficam DISPONÍVEIS de novo, com o botão "Demonstrar interesse
  /// novamente".
  final Set<int> _concluidoAntes = {};

  /// Foto do [_emAndamento] tirada NA CARGA: controla a ORDENAÇÃO (em andamento
  /// vão para o fim). Interesses demonstrados agora só mudam de posição na
  /// próxima recarga — o card não "teleporta" na frente do usuário.
  Set<int> _emAndamentoNaCarga = {};

  /// Foto do [_concluidoAntes] na CARGA: controla a ORDENAÇÃO das
  /// "demonstrar interesse novamente" (ficam depois das disponíveis e antes das
  /// em andamento), sem o card teleportar ao interagir.
  Set<int> _concluidoAntesNaCarga = {};

  final Set<int> _enviandoInteresse = {}; // ids com POST em andamento (anti duplo)
  bool _carregando = true;
  bool _erroCarga = false;
  int? _doadorId;

  String _busca = '';
  String? _categoria; // null = todas
  bool _soUrgentes = false;

  // ---- Polling em tempo real ----
  Timer? _poll;

  // Intervalo do polling: bem espaçado com navegação simplificada (menos
  // rede/movimento para quem prefere calma), leve no uso normal.
  Duration get _intervaloPoll => ConfigController.instance.navegacaoSimplificada
      ? const Duration(seconds: 30)
      : const Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregar();
    if (widget.ativa) _iniciarPoll();
  }

  @override
  void didUpdateWidget(FeedNecessidadesScreen old) {
    super.didUpdateWidget(old);
    // O shell troca [ativa] ao entrar/sair da aba Explorar.
    if (widget.ativa && !old.ativa) {
      _carregar(silencioso: true); // atualiza na hora ao voltar à aba
      _iniciarPoll();
    } else if (!widget.ativa && old.ativa) {
      _pararPoll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pararPoll();
    super.dispose();
  }

  // Pausa o polling em segundo plano; retoma (e atualiza) ao voltar, se visível.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      if (widget.ativa) {
        _carregar(silencioso: true);
        _iniciarPoll();
      }
    } else if (estado == AppLifecycleState.paused ||
        estado == AppLifecycleState.hidden) {
      _pararPoll();
    }
  }

  void _iniciarPoll() {
    _poll?.cancel();
    // Polling silencioso enquanto a aba está visível. Com navegação
    // simplificada o intervalo é bem maior (30s) — menos rede/movimento.
    _poll = Timer.periodic(_intervaloPoll, (_) {
      if (!mounted || !widget.ativa) return;
      _carregar(silencioso: true);
    });
  }

  void _pararPoll() {
    _poll?.cancel();
    _poll = null;
  }

  /// Carrega necessidades + interesses + favoritos. Com [silencioso] = true
  /// (polling / retorno à aba) não mostra o spinner nem apaga a lista atual em
  /// caso de falha — a atualização é "invisível" até algo mudar.
  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erroCarga = false;
      });
    }
    try {
      final usuario = await _sessionService.obterUsuario();
      final lista = await _necessidadeService.listarAbertas();

      // Interesses do doador: agrupa por necessidadeId e olha o mais recente
      // (maior id) para separar EM ANDAMENTO (PENDENTE/ACEITO) de CONCLUÍDO.
      // Só as em andamento contam como "interesse demonstrado". Falha aqui não
      // derruba o feed (degrada para "nenhum").
      final emAndamento = <int>{};
      final concluidoAntes = <int>{};
      if (usuario != null) {
        try {
          final interesses = await _interesseService.meusMatches(usuario.id);
          // necessidadeId -> lista de interesses (para achar o mais recente).
          final porNecessidade = <int, List<dynamic>>{};
          for (final i in interesses) {
            final nid = i.necessidadeId;
            if (nid == null) continue;
            porNecessidade.putIfAbsent(nid, () => []).add(i);
          }
          for (final entrada in porNecessidade.entries) {
            final itens = entrada.value..sort((a, b) => a.id.compareTo(b.id));
            // "Em andamento" se QUALQUER interesse desta necessidade está
            // PENDENTE ou ACEITO (o backend só permite um ativo por vez).
            final temAtivo = itens.any(
                (i) => i.status == 'PENDENTE' || i.status == 'ACEITO');
            final temConcluido = itens.any((i) => i.status == 'CONCLUIDO');
            if (temAtivo) {
              emAndamento.add(entrada.key);
            } else if (temConcluido) {
              concluidoAntes.add(entrada.key);
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _doadorId = usuario?.id;
        _necessidades = lista;
        _emAndamento
          ..clear()
          ..addAll(emAndamento);
        _concluidoAntes
          ..clear()
          ..addAll(concluidoAntes);
        _emAndamentoNaCarga = Set.of(emAndamento);
        _concluidoAntesNaCarga = Set.of(concluidoAntes);
        _carregando = false;
        _erroCarga = false;
      });
    } catch (e) {
      if (!mounted) return;
      // No polling silencioso, falha momentânea não estraga a tela carregada.
      if (silencioso) return;
      // Distingue "sem dados" de "a API caiu": mostra estado de erro com retry.
      setState(() {
        _carregando = false;
        _erroCarga = true;
      });
    }
  }

  Future<void> _demonstrarInteresse(Necessidade n) async {
    if (_doadorId == null) {
      AppSnackbar.erro(context, 'Você precisa estar logado como doador.');
      return;
    }
    // Guarda contra toque duplo: só bloqueia se já está enviando ou EM
    // ANDAMENTO (concluído antes pode demonstrar de novo).
    if (_enviandoInteresse.contains(n.id) || _emAndamento.contains(n.id)) {
      return;
    }
    setState(() => _enviandoInteresse.add(n.id));
    try {
      await _interesseService.demonstrarInteresse(
        necessidadeId: n.id,
        doadorId: _doadorId!,
      );
      if (!mounted) return;
      setState(() {
        _enviandoInteresse.remove(n.id);
        _emAndamento.add(n.id);
        _concluidoAntes.remove(n.id); // agora tem interesse ativo de novo
      });
      AppSnackbar.sucesso(context, 'Interesse enviado! A ONG vai avaliar. 💚');
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviandoInteresse.remove(n.id));
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  // Categorias presentes nos dados, ja normalizadas para o valor canonico
  // (utils/categorias.dart) — evita chips duplicados tipo "Alimento" e
  // "Alimentos" quando ha dados legados.
  List<String> get _categorias {
    final set = _necessidades
        .map((n) => Categorias.normalizar(n.categoria))
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  List<Necessidade> get _filtradas {
    final q = _busca.toLowerCase().trim();

    final lista = _necessidades.where((n) {
      final bateBusca = q.isEmpty ||
          n.titulo.toLowerCase().contains(q) ||
          (n.ongNome ?? '').toLowerCase().contains(q) ||
          n.categoria.toLowerCase().contains(q);
      final bateCategoria = _categoria == null ||
          Categorias.normalizar(n.categoria) == _categoria;
      final bateUrgente = !_soUrgentes || n.urgente;
      return bateBusca && bateCategoria && bateUrgente;
    }).toList();

    // ---- CHAVE DE ORDENAÇÃO ----
    // Particiona por ESTADO do interesse (grupo primário); dentro de cada
    // estado, URGENTES sempre primeiro e depois dataCriacao mais RECENTE no topo.
    //   estado 0 = DISPONÍVEL (nunca demonstrado) — o topo (ação possível)
    //   estado 1 = "DEMONSTRAR NOVAMENTE" (última doação já CONCLUÍDA) — depois
    //              de todas as disponíveis e antes das em andamento
    //   estado 2 = interesse EM ANDAMENTO (PENDENTE/ACEITO) — por último
    // Usa as FOTOS da carga (não os sets vivos) para o card não teleportar
    // assim que o doador demonstra interesse (reordena só na próxima recarga).
    int estado(Necessidade n) {
      if (_emAndamentoNaCarga.contains(n.id)) return 2;
      if (_concluidoAntesNaCarga.contains(n.id)) return 1;
      return 0;
    }

    // dataCriacao ISO ordena lexicograficamente; null vira "" (mais antigo).
    lista.sort((a, b) {
      final e = estado(a).compareTo(estado(b));
      if (e != 0) return e;
      // Urgentes sempre acima dentro do mesmo estado.
      if (a.urgente != b.urgente) return a.urgente ? -1 : 1;
      // Mais recente primeiro.
      return (b.dataCriacao ?? '').compareTo(a.dataCriacao ?? '');
    });
    return lista;
  }

  // Abre o detalhe da necessidade. O detalhe espelha os estados "em andamento"
  // e "concluído antes" e avisa de volta quando o doador demonstra interesse
  // lá — o card do feed muda na hora (e reordena só na próxima recarga).
  void _abrirDetalhe(Necessidade n) {
    Navigator.push(
      context,
      PageTransition.fade(NecessidadeDetalheScreen(
        necessidade: n,
        jaInteressado: _emAndamento.contains(n.id),
        jaConcluido: _concluidoAntes.contains(n.id),
        onInteresseDemonstrado: () {
          if (!mounted) return;
          setState(() {
            _emAndamento.add(n.id);
            _concluidoAntes.remove(n.id);
          });
        },
      )),
    );
  }

  void _abrirPerfilOng(Necessidade n) {
    if (n.ongId == null) return;
    Navigator.push(
      context,
      PageTransition.fade(PerfilPublicoOngScreen(
        ongId: n.ongId!,
        ongNome: n.ongNome ?? 'ONG',
      )),
    );
  }

  Widget _card(Necessidade n) {
    final cs = Theme.of(context).colorScheme;
    final emAndamento = _emAndamento.contains(n.id);
    final concluido = !emAndamento && _concluidoAntes.contains(n.id);
    final enviando = _enviandoInteresse.contains(n.id);
    final postado = tempoRelativo(n.dataCriacao);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias, // recorta a capa nos cantos arredondados
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        // Toque no CORPO do card abre o detalhe; o botão de interesse e
        // a linha da ONG absorvem os próprios toques.
        child: InkWell(
          onTap: () => _abrirDetalhe(n),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capa visual por categoria (estilo marketplace); o selo URGENTE
          // fica sobre a capa.
          CapaCategoria(
            categoria: n.categoria,
            selo: n.urgente ? _badgeUrgente() : null,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.titulo,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // ONG + verificada + nota — linha TOCÁVEL: abre o perfil
                // público da ONG (quando o backend informa o ongId).
                InkWell(
                  onTap: n.ongId != null ? () => _abrirPerfilOng(n) : null,
                  borderRadius: AppRadius.brSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.handshake,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            n.ongNome ?? 'ONG',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (n.ongVerificada) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 15, color: AppColors.primary),
                        ],
                        if (n.ongTotalAvaliacoes > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.star_rounded,
                              size: 15, color: AppColors.ouro),
                          const SizedBox(width: 2),
                          Text(
                            n.ongNotaMedia.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                        if (n.ongId != null) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right,
                              size: 16, color: cs.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  n.descricao,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if ((n.ongCidade ?? '').isNotEmpty || postado.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            if ((n.ongCidade ?? '').isNotEmpty) ...[
                              Icon(Icons.location_on_outlined,
                                  size: 15, color: cs.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  n.ongCidade!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant),
                                ),
                              ),
                            ],
                            // "há X dias" discreto (some quando o backend
                            // ainda não envia dataCriacao).
                            if (postado.isNotEmpty)
                              Text(
                                (n.ongCidade ?? '').isNotEmpty
                                    ? ' · $postado'
                                    : postado,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    // Transicao suave entre os estados do botão principal
                    // (o "momento de recompensa" da acao principal do app).
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: _botaoCard(n,
                          emAndamento: emAndamento,
                          concluido: concluido,
                          enviando: enviando),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  // Botão de interesse do card, com 3 estados:
  // - EM ANDAMENTO: "Interesse demonstrado" (desabilitado);
  // - CONCLUÍDO ANTES: "Demonstrar interesse novamente" (habilitado);
  // - novo: "Tenho interesse".
  Widget _botaoCard(Necessidade n,
      {required bool emAndamento,
      required bool concluido,
      required bool enviando}) {
    if (emAndamento) {
      return FilledButton.tonalIcon(
        key: const ValueKey('enviado'),
        onPressed: null,
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Interesse demonstrado'),
      );
    }
    return FilledButton.icon(
      key: ValueKey(concluido ? 'novamente' : 'interesse'),
      onPressed: enviando ? null : () => _demonstrarInteresse(n),
      icon: enviando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.favorite, size: 18),
      label: Text(enviando
          ? 'Enviando...'
          : (concluido ? 'Demonstrar novamente' : 'Tenho interesse')),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Selo solido (fundo vermelho, texto branco) para ficar legivel SOBRE a
  // capa colorida da categoria.
  Widget _badgeUrgente() {
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

  Widget _vazio(String msg) {
    return _vazioWidget(
        EmptyState(icone: Icons.inbox_outlined, mensagem: msg));
  }

  // Envolve um EmptyState num ListView para o pull-to-refresh continuar
  // funcionando (permite puxar para recarregar mesmo sem itens/em erro).
  Widget _vazioWidget(Widget conteudo) {
    return ListView(
      children: [const SizedBox(height: 100), conteudo],
    );
  }

  Widget _barraFiltros() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _busca = v),
            decoration: InputDecoration(
              hintText: 'Buscar por título, ONG ou categoria...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: AppRadius.brXl,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.brXl,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            // Altura dos chips escala com a fonte (evita overflow de pixels).
            height: 40 * fatorFonte(context),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('Urgentes'),
                  selected: _soUrgentes,
                  selectedColor: AppColors.error.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.error,
                  onSelected: (v) => setState(() => _soUrgentes = v),
                ),
                const SizedBox(width: AppSpacing.sm),
                ..._categorias.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      avatar: Icon(Categorias.icone(c),
                          size: 16, color: AppColors.primary),
                      label: Text(Categorias.rotulo(c)),
                      selected: _categoria == c,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      onSelected: (v) =>
                          setState(() => _categoria = v ? c : null),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas;
    return Scaffold(
      appBar: AppBar(
        // Aba do shell: nunca mostra seta de voltar.
        automaticallyImplyLeading: false,
        title: const Text('Explorar'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: Column(
        children: [
          if (!_carregando && _necessidades.isNotEmpty) _barraFiltros(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              color: AppColors.primary,
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _erroCarga
                      ? _vazioWidget(const EmptyState(
                          icone: Icons.cloud_off_outlined,
                          mensagem: 'Não foi possível carregar',
                          detalhe: 'Verifique sua conexão e tente novamente.',
                        ))
                      : _necessidades.isEmpty
                          ? _vazio('Nenhuma necessidade aberta no momento.')
                          : filtradas.isEmpty
                              ? _vazio('Nenhuma necessidade com esse filtro.')
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.md),
                                  itemCount: filtradas.length,
                                  itemBuilder: (context, i) =>
                                      _card(filtradas[i]),
                                ),
            ),
          ),
        ],
      ),
    );
  }
}
