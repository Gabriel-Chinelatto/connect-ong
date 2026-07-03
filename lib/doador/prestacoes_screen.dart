import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/prestacao.dart';
import '../services/prestacao_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';
import '../utils/tempo.dart';
import '../widgets/common/visualizador_imagem.dart';

/// Exibe as prestacoes de contas de uma ONG referentes a um match
/// (interesseId): titulo, relato, ONG, necessidade, data, valor utilizado em
/// R$ (quando informado) e o carrossel das fotos comprovante (tap → tela
/// cheia). Campos ausentes em prestacoes antigas sao simplesmente omitidos.
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

  // Fotos (base64) decodificadas UMA vez por prestacao, na carga — evita
  // decodificar a cada rebuild da lista.
  final Map<int, List<Uint8List>> _fotosPorPrestacao = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await _service.listar(widget.interesseId);
      final fotos = <int, List<Uint8List>>{};
      for (final p in lista) {
        final decodificadas = <Uint8List>[];
        for (final f in p.fotos) {
          try {
            decodificadas.add(base64Decode(f));
          } catch (_) {
            // base64 corrompido: ignora só esta foto.
          }
        }
        fotos[p.id] = decodificadas;
      }
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _fotosPorPrestacao
          ..clear()
          ..addAll(fotos);
        _carregando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _card(Prestacao p) {
    final cs = Theme.of(context).colorScheme;
    final temFotoLegado = (p.fotoUrl ?? '').trim().isNotEmpty;
    final fotos = _fotosPorPrestacao[p.id] ?? const <Uint8List>[];
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
          // Legado: prestacoes antigas com foto unica por URL.
          if (fotos.isEmpty && temFotoLegado)
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
                // ONG · necessidade (quando o backend informa).
                if ((p.ongNome ?? '').isNotEmpty ||
                    (p.necessidadeTitulo ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if ((p.ongNome ?? '').isNotEmpty) p.ongNome!,
                      if ((p.necessidadeTitulo ?? '').isNotEmpty)
                        p.necessidadeTitulo!,
                    ].join(' · '),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
                if (p.descricao.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(p.descricao,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, height: 1.4)),
                ],
                // Valor utilizado em R$ (quando a ONG informou).
                if (p.valorUtilizado != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Valor utilizado: '
                            '${formatarReais(p.valorUtilizado!)}',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Carrossel das fotos comprovante (tap → tela cheia).
                if (fotos.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: fotos.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) => Semantics(
                        button: true,
                        label:
                            'Foto ${i + 1} da prestação, toque para ampliar',
                        child: InkWell(
                          borderRadius: AppRadius.brMd,
                          onTap: () => VisualizadorImagem.abrir(
                            context,
                            fotos[i],
                            titulo: p.titulo,
                          ),
                          child: ClipRRect(
                            borderRadius: AppRadius.brMd,
                            child: Image.memory(
                              fotos[i],
                              width: 140,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (dataCurtaDeIso(p.dataCriacao).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    dataCurtaDeIso(p.dataCriacao),
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
