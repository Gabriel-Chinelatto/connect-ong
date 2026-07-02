import 'package:flutter/material.dart';

import '../models/necessidade.dart';
import '../services/necessidade_service.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';
import '../services/perfil_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/categorias.dart';
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
  bool _carregando = true;
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
    setState(() => _carregando = true);
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
      setState(() => _carregando = false);
      AppSnackbar.erro(context, 'Erro ao carregar necessidades');
    }
  }

  Future<void> _demonstrarInteresse(Necessidade n) async {
    if (_doadorId == null) {
      AppSnackbar.erro(context, 'Você precisa estar logado como doador.');
      return;
    }
    try {
      await _interesseService.demonstrarInteresse(
        necessidadeId: n.id,
        doadorId: _doadorId!,
      );
      if (!mounted) return;
      setState(() => _jaInteressado.add(n.id));
      AppSnackbar.sucesso(context, 'Interesse enviado! A ONG vai avaliar. 💚');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, e.toString().replaceFirst('Exception: ', ''));
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  n.titulo,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (n.urgente) ...[
                const SizedBox(width: AppSpacing.sm),
                _badgeUrgente(),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // ONG + verificada + nota
          Row(
            children: [
              const Icon(Icons.handshake, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  n.ongNome ?? 'ONG',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
              if (n.ongVerificada) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, size: 15, color: AppColors.primary),
              ],
              if (n.ongTotalAvaliacoes > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.star_rounded, size: 15, color: AppColors.ouro),
                const SizedBox(width: 2),
                Text(
                  n.ongNotaMedia.toStringAsFixed(1),
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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
              _chipCategoria(n.categoria),
              const Spacer(),
              interessado
                  ? FilledButton.tonalIcon(
                      onPressed: null,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Enviado'),
                    )
                  : FilledButton.icon(
                      onPressed: () => _demonstrarInteresse(n),
                      icon: const Icon(Icons.favorite, size: 18),
                      label: const Text('Tenho interesse'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeUrgente() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: AppRadius.brSm,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high, size: 13, color: AppColors.error),
          SizedBox(width: 2),
          Text('Urgente',
              style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _chipCategoria(String categoria) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Categorias.icone(categoria),
              size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            Categorias.rotulo(categoria),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _vazio(String msg) {
    // Dentro de um ListView para o pull-to-refresh continuar funcionando.
    return ListView(
      children: [
        const SizedBox(height: 100),
        EmptyState(icone: Icons.inbox_outlined, mensagem: msg),
      ],
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
            height: 40,
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
                  : _necessidades.isEmpty
                      ? _vazio('Nenhuma necessidade aberta no momento.')
                      : filtradas.isEmpty
                          ? _vazio('Nenhuma necessidade com esse filtro.')
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: filtradas.length,
                              itemBuilder: (context, i) => _card(filtradas[i]),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
