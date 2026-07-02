import 'package:flutter/material.dart';

import '../../doacao.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/categorias.dart';

/// Cartao que exibe os dados de uma [Doacao] em lista.
///
/// Mostra categoria (icone/cor via utils/categorias.dart), descricao, tipo,
/// quantidade e selos de "Urgente"/"Novo", alem de acoes opcionais de
/// editar/excluir. Cores do TEMA (dark mode ok).
class DoacaoCard extends StatelessWidget {
  final Doacao doacao;

  final VoidCallback? onEditar;
  final VoidCallback? onExcluir;

  const DoacaoCard({
    super.key,
    required this.doacao,
    this.onEditar,
    this.onExcluir,
  });

  // Cor de acento por categoria (sobre o valor canonico normalizado).
  Color _corCategoria() {
    switch (Categorias.normalizar(doacao.categoria)) {
      case 'Alimentos':
        return AppColors.primary;
      case 'Roupas':
        return AppColors.info;
      case 'Higiene':
        return const Color(0xFF7C3AED); // roxo de acento
      case 'Educacao':
        return AppColors.warning;
      case 'Brinquedos':
        return const Color(0xFFDB2777); // rosa de acento
      case 'Saude':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cor = _corCategoria();
    final icone = Categorias.icone(doacao.categoria);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
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
              CircleAvatar(
                backgroundColor: cor.withValues(alpha: 0.12),
                child: Icon(icone, color: cor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  doacao.nome,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (onEditar != null)
                IconButton(
                  tooltip: 'Editar',
                  onPressed: onEditar,
                  icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
                ),
              if (onExcluir != null)
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: onExcluir,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            doacao.descricao,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _chip(context, Categorias.rotulo(doacao.categoria),
                  icone: icone, cor: cor),
              _chip(context, doacao.tipo,
                  icone: Icons.inventory_2_outlined),
              _chip(context, '${doacao.quantidade} unidades',
                  icone: Icons.numbers),
              if (doacao.urgente)
                _chip(context, 'Urgente',
                    icone: Icons.warning_amber, cor: AppColors.error),
              if (doacao.novo)
                _chip(context, 'Novo',
                    icone: Icons.verified, cor: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String texto,
      {required IconData icone, Color? cor}) {
    final cs = Theme.of(context).colorScheme;
    final corTexto = cor ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor != null
            ? cor.withValues(alpha: 0.10)
            : cs.surfaceContainerHighest,
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 15, color: corTexto),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
                color: corTexto, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
