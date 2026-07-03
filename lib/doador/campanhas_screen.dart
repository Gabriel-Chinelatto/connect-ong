import 'package:flutter/material.dart';

import '../models/campanha.dart';
import '../services/campanha_service.dart';
import '../services/favorito_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/categorias.dart';
import '../utils/page_transition.dart';
import '../widgets/cards/capa_categoria.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/empty_state.dart';

import 'doar_pix_screen.dart';

/// Lista as campanhas ativas das ONGs que o doador pode apoiar, com capa
/// ilustrativa por categoria, AUTO-FILTRO de categorias (chips gerados das
/// categorias que existem nas campanhas carregadas) e favoritos.
///
/// "Contribuir" abre o fluxo PIX simulado completo ([DoarPixScreen] com a
/// campanha), substituindo o antigo dialog de valor.
class CampanhasScreen extends StatefulWidget {
  const CampanhasScreen({super.key});

  @override
  State<CampanhasScreen> createState() => _CampanhasScreenState();
}

class _CampanhasScreenState extends State<CampanhasScreen> {
  final CampanhaService _service = CampanhaService();
  final FavoritoService _favService = FavoritoService();
  List<Campanha> _campanhas = [];
  bool _carregando = true;
  int? _usuarioId;
  Set<int> _favCampanhas = {};

  /// Categoria selecionada no filtro (null = "Todas").
  String? _filtroCategoria;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregar();
  }

  Future<void> _carregarUsuario() async {
    final u = await SessionService().obterUsuario();
    if (!mounted) return;
    _usuarioId = u?.id;
    if (_usuarioId == null) return;
    try {
      final favs = await _favService.ids(_usuarioId!, 'CAMPANHA');
      if (!mounted) return;
      setState(() => _favCampanhas = favs);
    } catch (_) {
      // segue sem coracao preenchido
    }
  }

  Future<void> _toggleFavorito(Campanha c) async {
    if (_usuarioId == null) return;
    final jaFavorito = _favCampanhas.contains(c.id);
    try {
      if (jaFavorito) {
        await _favService.remover(_usuarioId!, 'CAMPANHA', c.id);
        if (!mounted) return;
        setState(() => _favCampanhas.remove(c.id));
      } else {
        await _favService.adicionar(_usuarioId!, 'CAMPANHA', c.id);
        if (!mounted) return;
        setState(() => _favCampanhas.add(c.id));
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.erro(context, 'Erro ao atualizar favorito');
    }
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await _service.listarAbertas();
      if (!mounted) return;
      setState(() {
        _campanhas = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  // Categoria "visual" da campanha (fallback amigável quando o backend não
  // informa categoria).
  String _categoriaDe(Campanha c) {
    final cat = c.categoria?.trim() ?? '';
    return cat.isEmpty ? 'Doações' : Categorias.normalizar(cat);
  }

  /// Categorias que EXISTEM nas campanhas carregadas, na ordem canônica
  /// (as desconhecidas vão para o fim, em ordem alfabética).
  List<String> get _categoriasExistentes {
    final presentes = _campanhas.map(_categoriaDe).toSet();
    final ordenadas = <String>[
      for (final c in Categorias.todas)
        if (presentes.remove(c.valor)) c.valor,
    ];
    ordenadas.addAll(presentes.toList()..sort());
    return ordenadas;
  }

  List<Campanha> get _filtradas => _filtroCategoria == null
      ? _campanhas
      : _campanhas.where((c) => _categoriaDe(c) == _filtroCategoria).toList();

  Future<void> _contribuir(Campanha c) async {
    // Fluxo PIX completo (valor → código → aguardando → comprovante).
    final concluiu = await Navigator.push<bool>(
      context,
      PageTransition.fade(DoarPixScreen(
        ongId: c.ongId,
        ongNome: c.ongNome ?? 'ONG',
        campanha: c,
      )),
    );
    // Recarrega para refletir o novo progresso da campanha.
    if (concluiu == true && mounted) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campanhas'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _campanhas.isEmpty
              ? _vazio()
              : Column(
                  children: [
                    _filtroChips(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _carregar,
                        color: AppColors.primary,
                        child: _filtradas.isEmpty
                            ? ListView(children: const [
                                SizedBox(height: 80),
                                EmptyState(
                                  icone: Icons.filter_alt_off_outlined,
                                  mensagem:
                                      'Nenhuma campanha nesta categoria',
                                  detalhe:
                                      'Toque em "Todas" para ver as demais.',
                                ),
                              ])
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics()),
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md, 0, AppSpacing.md,
                                    AppSpacing.md),
                                itemCount: _filtradas.length,
                                itemBuilder: (_, i) => _card(_filtradas[i]),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // Chips horizontais de categoria ("Todas" + categorias existentes).
  Widget _filtroChips() {
    final categorias = _categoriasExistentes;
    if (categorias.length <= 1) return const SizedBox(height: AppSpacing.sm);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: _filtroCategoria == null,
              onSelected: (_) => setState(() => _filtroCategoria = null),
            ),
          ),
          for (final cat in categorias)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                avatar: Icon(
                  Categorias.icone(cat),
                  size: 16,
                  color: _filtroCategoria == cat
                      ? AppColors.primary
                      : Categorias.cor(cat),
                ),
                label: Text(Categorias.rotulo(cat)),
                selected: _filtroCategoria == cat,
                onSelected: (sel) =>
                    setState(() => _filtroCategoria = sel ? cat : null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _vazio() {
    return const EmptyState(
      icone: Icons.campaign_outlined,
      mensagem: 'Nenhuma campanha ativa no momento',
    );
  }

  Widget _card(Campanha c) {
    final cs = Theme.of(context).colorScheme;
    final categoria = _categoriaDe(c);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capa ilustrativa por categoria (gradiente + ícone marca d'água).
          CapaCategoria(
            categoria: categoria,
            altura: 92,
            selo: c.destaque ? _seloDestaque() : null,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        c.titulo,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface),
                      ),
                    ),
                    if (_usuarioId != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: _favCampanhas.contains(c.id)
                            ? 'Remover dos favoritos'
                            : 'Favoritar',
                        onPressed: () => _toggleFavorito(c),
                        icon: Icon(
                          _favCampanhas.contains(c.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: AppColors.error,
                        ),
                      ),
                  ],
                ),
                if (c.ongNome != null) ...[
                  const SizedBox(height: 2),
                  Text(c.ongNome!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.primary)),
                ],
                const SizedBox(height: 10),
                Text(c.descricao,
                    style: TextStyle(
                        fontSize: 14, color: cs.onSurfaceVariant, height: 1.4)),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: AppRadius.brSm,
                  child: LinearProgressIndicator(
                    value: c.progresso / 100,
                    minHeight: 10,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          'R\$ ${c.valorArrecadado.toStringAsFixed(0)} de '
                          'R\$ ${c.metaValor.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                    ),
                    Text('${c.progresso}%',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _contribuir(c),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd),
                    ),
                    icon: const Icon(Icons.pix),
                    label: const Text('Contribuir'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seloDestaque() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: AppRadius.brSm,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: AppColors.ouro),
          SizedBox(width: 3),
          Text('Destaque',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
