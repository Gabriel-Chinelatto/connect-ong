import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/estatistica_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/empty_state.dart';

/// Mural de Impacto: vitrine pública dos números coletivos da plataforma
/// (ONGs, doadores, conexões, prestações, valor doado) com destaque para as
/// pessoas alcançadas. Reaproveita GET /publico/estatisticas.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
class MuralImpactoScreen extends StatefulWidget {
  const MuralImpactoScreen({super.key});

  @override
  State<MuralImpactoScreen> createState() => _MuralImpactoScreenState();
}

class _MuralImpactoScreenState extends State<MuralImpactoScreen> {
  final EstatisticaService _service = EstatisticaService();
  EstatisticasPublicas _stats = EstatisticasPublicas.zero;
  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final s = await _service.carregar();
      if (!mounted) return;
      setState(() {
        _stats = s;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  // Estimativa transparente de pessoas alcançadas: cada conexão (match) e cada
  // doação financeira representa, no minimo, uma pessoa/familia atendida.
  int get _pessoasAlcancadas =>
      _stats.totalMatches + _stats.totalDoacoesFinanceiras;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nosso Impacto'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? _vazio()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _hero(),
                      _destaquePessoas(),
                      _grade(),
                      const SizedBox(height: 28),
                      _rodape(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
    );
  }

  Widget _vazio() {
    return EmptyState(
      icone: Icons.error_outline,
      mensagem: 'Não foi possível carregar o impacto',
      acaoRotulo: 'Tentar de novo',
      onAcao: _carregar,
    );
  }

  Widget _hero() {
    // Hero mantem o gradiente da marca (identidade), com conteudo branco por cima.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.brXl,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: SvgPicture.asset(
              'assets/images/impacto_hero.svg',
              height: 150,
              semanticsLabel: 'Ilustracao de impacto',
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Juntos transformamos vidas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'O resultado coletivo de cada doacao na plataforma',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _destaquePessoas() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.diversity_1, color: AppColors.primary, size: 36),
          const SizedBox(height: AppSpacing.sm),
          _contador(_pessoasAlcancadas,
              style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          Text('pessoas alcancadas (estimativa)',
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _grade() {
    final itens = <_ItemStat>[
      _ItemStat(Icons.apartment_outlined, _stats.totalOngs, 'ONGs parceiras'),
      _ItemStat(Icons.favorite_outline, _stats.totalDoadores, 'Doadores'),
      _ItemStat(Icons.volunteer_activism, _stats.totalNecessidades,
          'Necessidades'),
      _ItemStat(Icons.handshake_outlined, _stats.totalMatches, 'Conexoes'),
      _ItemStat(
          Icons.receipt_long_outlined, _stats.totalPrestacoes, 'Prestacoes'),
      _ItemStat(Icons.pix, _stats.totalDoacoesFinanceiras, 'Doacoes PIX'),
    ];
    // Linhas flexíveis (IntrinsicHeight) em vez de grade com razão de aspecto
    // fixa: a altura acompanha o conteúdo e não estoura com fonte grande nem
    // em telas estreitas.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          for (var i = 0; i < itens.length; i += 2)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _cardStat(itens[i])),
                    const SizedBox(width: 14),
                    Expanded(
                      child: i + 1 < itens.length
                          ? _cardStat(itens[i + 1])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardStat(_ItemStat i) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(i.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          _contador(i.valor,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          Text(i.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _rodape() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppRadius.brLg,
        ),
        child: Row(
          children: [
            Icon(Icons.savings_outlined, color: AppColors.primary, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total doado via PIX',
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurfaceVariant)),
                  Text('R\$ ${_stats.valorTotalDoado.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Contador que anima de 0 ate o valor final.
  Widget _contador(int valor, {required TextStyle style}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor.toDouble()),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOut,
      builder: (_, v, _) => Text('${v.round()}', style: style),
    );
  }
}

class _ItemStat {
  final IconData icon;
  final int valor;
  final String label;
  const _ItemStat(this.icon, this.valor, this.label);
}
