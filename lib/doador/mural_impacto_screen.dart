import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/estatistica_service.dart';
import '../theme/app_colors.dart';

/// Mural de Impacto: vitrine pública dos números coletivos da plataforma
/// (ONGs, doadores, conexões, prestações, valor doado) com destaque para as
/// pessoas alcançadas. Reaproveita GET /publico/estatisticas.
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nosso Impacto'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? _vazio()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _hero(),
                      _destaquePessoas(),
                      _grade(),
                      const SizedBox(height: 28),
                      _rodape(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 72, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Nao foi possivel carregar o impacto',
              style: GoogleFonts.poppins(color: Colors.black54)),
          const SizedBox(height: 12),
          TextButton(onPressed: _carregar, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }

  Widget _hero() {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'O resultado coletivo de cada doacao na plataforma',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _destaquePessoas() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.diversity_1, color: AppColors.primary, size: 36),
          const SizedBox(height: 8),
          _contador(_pessoasAlcancadas,
              style: GoogleFonts.poppins(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          Text('pessoas alcancadas (estimativa)',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.5,
        children: [for (final i in itens) _cardStat(i)],
      ),
    );
  }

  Widget _cardStat(_ItemStat i) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(i.icon, color: AppColors.primary, size: 22),
          ),
          const Spacer(),
          _contador(i.valor,
              style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text(i.label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _rodape() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
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
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary)),
                  Text('R\$ ${_stats.valorTotalDoado.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
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
