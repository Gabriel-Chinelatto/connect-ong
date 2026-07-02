import 'package:flutter/material.dart';

import '../models/prestacao.dart';
import '../services/prestacao_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Exibe as prestacoes de contas de uma ONG referentes a um match (interesseId),
/// mostrando como a doacao foi aplicada, com texto e foto comprovante.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
class PrestacoesScreen extends StatefulWidget {
  final int interesseId;
  final String ongNome;

  const PrestacoesScreen({
    super.key,
    required this.interesseId,
    required this.ongNome,
  });

  @override
  State<PrestacoesScreen> createState() => _PrestacoesScreenState();
}

class _PrestacoesScreenState extends State<PrestacoesScreen> {
  final PrestacaoService _service = PrestacaoService();

  List<Prestacao> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await _service.listar(widget.interesseId);
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _card(Prestacao p) {
    final cs = Theme.of(context).colorScheme;
    final temFoto = (p.fotoUrl ?? '').trim().isNotEmpty;
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
          if (temFoto)
            Image.network(
              p.fotoUrl!.trim(),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        p.titulo,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
                if (p.descricao.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(p.descricao,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, height: 1.4)),
                ],
                if (p.dataCriacao != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    p.dataCriacao!.split('T').first,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Prestação de contas — ${widget.ongNome}'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        color: AppColors.primary,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _itens.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'A ONG ainda não publicou uma prestação de contas para esta doação.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _itens.length,
                    itemBuilder: (_, i) => _card(_itens[i]),
                  ),
      ),
    );
  }
}
