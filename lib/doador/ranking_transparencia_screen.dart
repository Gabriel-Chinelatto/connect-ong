import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ranking_ong.dart';
import '../services/ranking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/page_transition.dart';
import '../widgets/feedback/empty_state.dart';
import 'perfil_publico_ong_screen.dart';

/// Tela publica com o ranking de transparencia das ONGs, ordenado por score.
/// Mostra posicao, medalha do nivel, nome, cidade e o score/nivel a direita.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
class RankingTransparenciaScreen extends StatefulWidget {
  const RankingTransparenciaScreen({super.key});

  @override
  State<RankingTransparenciaScreen> createState() =>
      _RankingTransparenciaScreenState();
}

class _RankingTransparenciaScreenState
    extends State<RankingTransparenciaScreen> {
  final RankingService _service = RankingService();
  List<RankingOng> _ranking = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await _service.listar();
      if (!mounted) return;
      setState(() {
        _ranking = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  // Cor da medalha por nivel de transparencia (tokens centralizados).
  Color _corNivel(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'OURO':
        return AppColors.ouro;
      case 'PRATA':
        return AppColors.prata;
      case 'BRONZE':
      default:
        return AppColors.bronze;
    }
  }

  // Rotulo amigavel (primeira maiuscula) do nivel.
  String _rotuloNivel(String nivel) {
    final n = nivel.toLowerCase();
    if (n.isEmpty) return 'Bronze';
    return n[0].toUpperCase() + n.substring(1);
  }

  void _abrirPerfil(RankingOng r) {
    Navigator.push(
      context,
      PageTransition.fade(
        PerfilPublicoOngScreen(ongId: r.ongId, ongNome: r.nome),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking de Transparencia'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _ranking.isEmpty
              ? _vazio()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _ranking.length,
                    itemBuilder: (_, i) => _card(_ranking[i], i + 1),
                  ),
                ),
    );
  }

  Widget _vazio() {
    return const EmptyState(
      icone: Icons.emoji_events_outlined,
      mensagem: 'Ranking ainda não disponível',
    );
  }

  Widget _card(RankingOng r, int posicao) {
    final cs = Theme.of(context).colorScheme;
    final cor = _corNivel(r.nivel);
    final top3 = posicao <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: top3
            ? Border.all(color: cor.withValues(alpha: 0.6), width: 1.5)
            : Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: () => _abrirPerfil(r),
        child: Row(
          children: [
            // Posicao
            SizedBox(
              width: 36,
              child: Text(
                '#$posicao',
                style: GoogleFonts.poppins(
                  fontSize: top3 ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: top3 ? cor : cs.onSurfaceVariant,
                ),
              ),
            ),
            // Medalha do nivel
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.workspace_premium, color: cor, size: 26),
            ),
            const SizedBox(width: 14),
            // Nome + cidade
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          r.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface),
                        ),
                      ),
                      if (r.verificada) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 16, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.cidade,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Score + nivel
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${r.score}',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
                Text(
                  _rotuloNivel(r.nivel),
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
