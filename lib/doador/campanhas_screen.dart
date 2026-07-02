import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/campanha.dart';
import '../services/campanha_service.dart';
import '../services/favorito_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/empty_state.dart';

/// Lista as campanhas ativas das ONGs que o doador pode apoiar, com opcao de
/// favoritar cada campanha (persistido por usuario via FavoritoService).
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
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
  String? _meuNome;
  int? _usuarioId;
  Set<int> _favCampanhas = {};

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregar();
  }

  Future<void> _carregarUsuario() async {
    final u = await SessionService().obterUsuario();
    if (!mounted) return;
    _meuNome = u?.nome;
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

  Future<void> _contribuir(Campanha c) async {
    final controller = TextEditingController();
    final valor = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contribuir com "${c.titulo}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [10, 25, 50, 100]
                  .map((v) => ActionChip(
                        label: Text('R\$ $v'),
                        onPressed: () => controller.text = v.toString(),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              Navigator.pop(ctx, v);
            },
            child: const Text('Contribuir'),
          ),
        ],
      ),
    );

    // Descarta o controller apos o dialogo fechar (evita vazamento).
    controller.dispose();

    if (valor == null || valor <= 0) return;
    try {
      final atualizada = await _service.contribuir(
        campanhaId: c.id,
        valor: valor,
        doadorNome: _meuNome,
      );
      if (!mounted) return;
      AppSnackbar.sucesso(
        context,
        atualizada.encerrada
            ? 'Obrigado! A campanha atingiu a meta! 🎉'
            : 'Obrigado pela contribuição de R\$ ${valor.toStringAsFixed(2)}!',
      );
      _carregar();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, e.toString().replaceFirst('Exception: ', ''));
    }
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
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _campanhas.length,
                    itemBuilder: (_, i) => _card(_campanhas[i]),
                  ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (c.destaque)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ouro.withValues(alpha: 0.2),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.ouro),
                      const SizedBox(width: 4),
                      Text('Destaque',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ouro)),
                    ],
                  ),
                ),
              Expanded(
                child: Text(
                  c.titulo,
                  style: GoogleFonts.poppins(
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
                style:
                    GoogleFonts.poppins(fontSize: 13, color: AppColors.primary)),
          ],
          const SizedBox(height: 10),
          Text(c.descricao,
              style: GoogleFonts.poppins(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('R\$ ${c.valorArrecadado.toStringAsFixed(0)} de '
                  'R\$ ${c.metaValor.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              Text('${c.progresso}%',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _contribuir(c),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.brMd),
              ),
              icon: const Icon(Icons.favorite),
              label: const Text('Contribuir'),
            ),
          ),
        ],
      ),
    );
  }
}
