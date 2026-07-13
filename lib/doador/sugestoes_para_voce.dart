import 'package:flutter/material.dart';

import '../models/necessidade.dart';
import '../services/assistente_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'necessidade_detalhe_screen.dart';
import 'perfil_publico_ong_screen.dart';

/// Seção "Sugestões para você": chama `POST /assistente/sugestoes` (a IA usa a
/// cidade e o histórico do doador via token) e mostra ONGs/necessidades
/// recomendadas como cards clicáveis. Carrega de forma preguiçosa e DEGRADA
/// para nada (SizedBox) quando não há sugestão ou a chamada falha — nunca
/// quebra o Início nem mostra um bloco vazio.
class SugestoesParaVoce extends StatefulWidget {
  const SugestoesParaVoce({super.key});

  @override
  State<SugestoesParaVoce> createState() => _SugestoesParaVoceState();
}

class _SugestoesParaVoceState extends State<SugestoesParaVoce> {
  final AssistenteService _service = AssistenteService();
  bool _carregando = true;
  String _frase = '';
  List<SugestaoAssistente> _sugestoes = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final r = await _service.sugestoesParaMim();
      if (!mounted) return;
      setState(() {
        _frase = r.resposta.trim();
        // Só cards clicáveis (com id).
        _sugestoes = r.sugestoes.where((s) => s.id != null).toList();
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false); // some sem alarde
    }
  }

  void _abrir(SugestaoAssistente s) {
    if (s.id == null) return;
    if (s.ehOng) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PerfilPublicoOngScreen(ongId: s.id!, ongNome: s.titulo),
        ),
      );
    } else if (s.ehNecessidade) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NecessidadeDetalheScreen(
            necessidade: Necessidade(
              id: s.id!,
              titulo: s.titulo,
              descricao: s.subtitulo,
              categoria: '',
              urgente: false,
              status: 'ABERTA',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto carrega, ou sem sugestões: não ocupa espaço no Início.
    if (_carregando || _sugestoes.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Sugestões para você',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (_frase.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _frase,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sugestoes.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, i) => _card(_sugestoes[i], cs),
          ),
        ),
        // Espaço para a próxima seção (só existe quando a seção aparece).
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _card(SugestaoAssistente s, ColorScheme cs) {
    final ehOng = s.ehOng;
    return SizedBox(
      width: 230,
      child: Material(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: () => _abrir(s),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: AppRadius.brSm,
                      ),
                      child: Icon(
                        ehOng ? Icons.corporate_fare : Icons.volunteer_activism,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ehOng ? 'ONG' : 'Necessidade',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18, color: cs.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (s.subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      s.subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
