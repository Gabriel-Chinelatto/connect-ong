import 'package:flutter/material.dart';

import '../../services/resumo_impacto_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Cartão "Resumo do impacto": busca em `POST /ia/resumo-impacto` um parágrafo
/// gerado por IA (a partir dos números REAIS da ONG) e o exibe no perfil
/// público da ONG. Carrega de forma preguiçosa e DEGRADA para nada (SizedBox)
/// se falhar ou vier vazio — nunca quebra nem polui a tela.
class ResumoImpactoIa extends StatefulWidget {
  final int ongId;

  const ResumoImpactoIa({super.key, required this.ongId});

  @override
  State<ResumoImpactoIa> createState() => _ResumoImpactoIaState();
}

class _ResumoImpactoIaState extends State<ResumoImpactoIa> {
  final ResumoImpactoService _service = ResumoImpactoService();
  bool _carregando = true;
  String _texto = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final r = await _service.obter(widget.ongId);
      if (!mounted) return;
      setState(() {
        _texto = r.resumo.trim();
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false); // some sem alarde
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nada a mostrar (erro/vazio): não ocupa espaço.
    if (!_carregando && _texto.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
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
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Resumo do impacto',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              // Selo discreto de "gerado por IA".
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'IA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_carregando)
            _placeholder(cs)
          else
            Text(
              _texto,
              style: TextStyle(fontSize: 14, height: 1.5, color: cs.onSurface),
            ),
        ],
      ),
    );
  }

  // Três "linhas" cinza enquanto a IA responde (percepção de carregamento).
  Widget _placeholder(ColorScheme cs) {
    Widget linha(double largura) => Container(
          height: 12,
          width: largura,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        linha(double.infinity),
        linha(double.infinity),
        linha(180),
      ],
    );
  }
}
