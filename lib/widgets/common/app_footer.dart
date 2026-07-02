import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Rodape padrao reutilizavel com creditos e direitos reservados do projeto.
///
/// Usa as cores do TEMA (colorScheme) para funcionar tanto no claro quanto no
/// escuro.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ano = DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Divider(color: cs.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            '© $ano Connect ONG — Todos os direitos reservados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Projeto acadêmico desenvolvido para a FECITEC.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
