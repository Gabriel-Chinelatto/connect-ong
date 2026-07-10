import 'package:flutter/material.dart';

/// Diálogo que explica o SISTEMA DE PONTOS (índice de transparência) da ONG:
/// o que faz a ONG ganhar e perder pontos e os níveis. Aparece pelo "i" no
/// perfil da ONG — ajuda o doador a entender o selo de transparência e mostra
/// à própria ONG como subir no ranking (mais pontos = mais visibilidade).
///
/// Números iguais aos do backend `TransparenciaService` (fonte da verdade).
void mostrarComoPontuar(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  Widget linha(IconData icon, Color cor, String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: cor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(texto,
                  style: TextStyle(fontSize: 13, color: cs.onSurface)),
            ),
          ],
        ),
      );

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.workspace_premium, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          const Expanded(child: Text('Índice de transparência')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vai de 0 a 100 e mede o quanto a ONG é confiável e transparente. '
              'Quanto maior, mais alto ela aparece no ranking.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Text('A ONG GANHA pontos com:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            linha(Icons.verified, Colors.blue, 'Selo de verificação: +25'),
            linha(Icons.star, Colors.amber.shade700,
                'Boas avaliações dos doadores: até +25'),
            linha(Icons.receipt_long, Colors.green,
                'Cada prestação de contas publicada: +5 (até +25)'),
            linha(Icons.campaign, Colors.green,
                'Cada campanha concluída: +5 (até +25)'),
            const SizedBox(height: 12),
            Text('A ONG PERDE pontos com:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            linha(Icons.timer_off, Colors.red,
                'Cada doação concluída sem prestar contas em 10 dias: −5'),
            const SizedBox(height: 14),
            Text('Níveis:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('🥇 Ouro: 75+   🥈 Prata: 45 a 74   🥉 Bronze: até 44',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}
