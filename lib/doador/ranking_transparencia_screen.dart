import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ranking_ong.dart';
import '../services/ranking_service.dart';
import '../theme/app_colors.dart';
import '../utils/page_transition.dart';
import 'perfil_publico_ong_screen.dart';

/// Tela publica com o ranking de transparencia das ONGs, ordenado por score.
/// Mostra posicao, medalha do nivel, nome, cidade e o score/nivel a direita.
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

  // Cor da medalha por nivel de transparencia.
  Color _corNivel(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'OURO':
        return const Color(0xFFF59E0B);
      case 'PRATA':
        return const Color(0xFF9CA3AF);
      case 'BRONZE':
      default:
        return const Color(0xFFCD7F32);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ranking de Transparencia'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _ranking.isEmpty
              ? _vazio()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _ranking.length,
                    itemBuilder: (_, i) => _card(_ranking[i], i + 1),
                  ),
                ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 80, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Ranking ainda nao disponivel',
              style: GoogleFonts.poppins(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _card(RankingOng r, int posicao) {
    final cor = _corNivel(r.nivel);
    final top3 = posicao <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: top3
            ? Border.all(color: cor.withValues(alpha: 0.6), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: top3 ? 0.08 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                  color: top3 ? cor : AppColors.textSecondary,
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
                              fontSize: 15, fontWeight: FontWeight.w700),
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
                        fontSize: 12, color: AppColors.textSecondary),
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
