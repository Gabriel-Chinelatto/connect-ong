import 'package:flutter/material.dart';

import '../models/necessidade.dart';
import '../services/api_service.dart';
import '../services/necessidade_service.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';
import '../services/perfil_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/categorias.dart';
import '../utils/escala.dart';
import '../widgets/cards/capa_categoria.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/empty_state.dart';

/// Feed das necessidades abertas das ONGs (aba Explorar), com filtros (busca,
/// categoria, urgentes) e priorizacao pela cidade do doador. Hero feature: ao
/// demonstrar interesse numa necessidade, cria um interesse que a ONG pode
/// aceitar (match), habilitando o chat.
///
/// Redesenho (Bloco 21 / Fase 4): consome o design system e usa cores do TEMA
/// (colorScheme), ficando correto no claro e no escuro.
class FeedNecessidadesScreen extends StatefulWidget {
  const FeedNecessidadesScreen({super.key});

  @override
  State<FeedNecessidadesScreen> createState() => _FeedNecessidadesScreenState();
}

class _FeedNecessidadesScreenState extends State<FeedNecessidadesScreen> {
  final NecessidadeService _necessidadeService = NecessidadeService();
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  List<Necessidade> _necessidades = [];
  final Set<int> _jaInteressado = {}; // ids onde o doador ja clicou
  final Set<int> _enviandoInteresse = {}; // ids com POST em andamento (anti duplo)
  bool _carregando = true;
  bool _erroCarga = false;
  int? _doadorId;

  String _busca = '';
  String? _categoria; // null = todas
  bool _soUrgentes = false;
  String _minhaCidade = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erroCarga = false;
    });
    try {
      final usuario = await _sessionService.obterUsuario();
      final lista = await _necessidadeService.listarAbertas();
      String cidade = '';
      if (usuario != null) {
        try {
          final perfil = await PerfilService().obter(usuario.id);
          cidade = (perfil['cidade'] ?? '').toString();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _doadorId = usuario?.id;
        _necessidades = lista;
        _minhaCidade = cidade;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
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
    // Guarda contra toque duplo: marca o id como "enviando" antes do await e
    // desabilita o botão enquanto o POST não retorna (evita interesse duplicado).
    if (_enviandoInteresse.contains(n.id) || _jaInteressado.contains(n.id)) {
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
        _jaInteressado.add(n.id);
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
    final cidade = _minhaCidade.toLowerCase().trim();

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

    // Ordenacao inteligente: urgentes primeiro, depois ONGs da mesma cidade.
    int score(Necessidade n) {
      int s = 0;
      if (n.urgente) s += 2;
      if (cidade.isNotEmpty &&
          (n.ongCidade ?? '').toLowerCase().trim() == cidade) {
        s += 1;
      }
      return s;
    }

    lista.sort((a, b) => score(b).compareTo(score(a)));
    return lista;
  }

  Widget _card(Necessidade n) {
    final cs = Theme.of(context).colorScheme;
    final interessado = _jaInteressado.contains(n.id);
    final enviando = _enviandoInteresse.contains(n.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias, // recorta a capa nos cantos arredondados
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
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
                // ONG + verificada + nota
                Row(
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
                  ],
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
                    if ((n.ongCidade ?? '').isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
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
                        ),
                      )
                    else
                      const Spacer(),
                    interessado
                        ? FilledButton.tonalIcon(
                            onPressed: null,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Enviado'),
                          )
                        : FilledButton.icon(
                            // Desabilita enquanto o POST esta em andamento.
                            onPressed:
                                enviando ? null : () => _demonstrarInteresse(n),
                            icon: enviando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.favorite, size: 18),
                            label: Text(enviando ? 'Enviando...' : 'Tenho interesse'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
