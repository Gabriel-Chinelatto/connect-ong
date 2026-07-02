import 'package:flutter/material.dart';

import '../models/atividade.dart';
import '../services/atividade_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/empty_state.dart';

/// Feed global de atividades recentes da plataforma (Timeline).
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
class TimelineAtividadesScreen extends StatefulWidget {
  const TimelineAtividadesScreen({super.key});

  @override
  State<TimelineAtividadesScreen> createState() =>
      _TimelineAtividadesScreenState();
}

class _TimelineAtividadesScreenState extends State<TimelineAtividadesScreen> {
  final AtividadeService _service = AtividadeService();
  List<Atividade> _atividades = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await _service.listarRecentes();
      if (!mounted) return;
      setState(() {
        _atividades = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  IconData _iconeDoTipo(String tipo) {
    switch (tipo) {
      case 'NECESSIDADE':
        return Icons.favorite_outline;
      case 'INTERESSE':
        return Icons.volunteer_activism;
      case 'PRESTACAO':
        return Icons.receipt_long_outlined;
      case 'CAMPANHA':
        return Icons.campaign_outlined;
      case 'DOACAO':
        return Icons.attach_money;
      case 'AVALIACAO':
        return Icons.star_outline;
      default:
        return Icons.notifications_none;
    }
  }

  /// Converte a dataCriacao ISO em um tempo relativo amigavel.
  /// Retorna vazio se a data for nula ou invalida.
  String _tempoRelativo(String? dataIso) {
    if (dataIso == null) return '';
    final data = DateTime.tryParse(dataIso);
    if (data == null) return '';
    final diff = DateTime.now().difference(data);
    if (diff.isNegative || diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return 'há ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividades'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _atividades.isEmpty
              ? _vazio()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _atividades.length,
                    itemBuilder: (_, i) => _card(_atividades[i]),
                  ),
                ),
    );
  }

  Widget _vazio() {
    return const EmptyState(
      icone: Icons.dynamic_feed_outlined,
      mensagem: 'Nenhuma atividade recente ainda',
    );
  }

  Widget _card(Atividade a) {
    final cs = Theme.of(context).colorScheme;
    final tempo = _tempoRelativo(a.dataCriacao);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconeDoTipo(a.tipo),
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.descricao,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: cs.onSurface,
                  ),
                ),
                if (a.ongNome != null && a.ongNome!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    a.ongNome!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                if (tempo.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    tempo,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
