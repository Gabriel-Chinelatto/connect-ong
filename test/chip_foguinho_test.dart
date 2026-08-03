import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/widgets/common/chip_foguinho.dart';

/// Regressão do bug relatado no teste da feira: no card estreito de "ONGs em
/// destaque" o chip 🔥 aparecia SÓ com a chama — o número da sequência sumia.
///
/// Causa: o card dava metade do espaço livre para um `Spacer()` e a outra
/// metade para o chip; espremido, o número (que estava num `Flexible` com
/// reticências) era cortado para nada. Estes testes provam que o número
/// continua visível em espaço apertado e com fonte grande.
void main() {
  Widget emLargura(double largura, Widget filho, {double escala = 1.0}) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: largura, child: filho),
        ),
      ),
    );
  }

  testWidgets('chip compacto mostra o NÚMERO mesmo espremido numa Row',
      (tester) async {
    // Row apertada, no formato do card de ONG em destaque (selo + chip + selo
    // de verificada), com pouquíssimo espaço sobrando.
    await tester.pumpWidget(emLargura(
      130,
      Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Flexible(child: Text('OURO')),
                SizedBox(width: 6),
                ChipFoguinho(dias: 29, compacto: true),
              ],
            ),
          ),
          const Icon(Icons.verified, size: 16),
        ],
      ),
    ));

    expect(find.text('29'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chip compacto continua legível com fonte grande (1.6)',
      (tester) async {
    await tester.pumpWidget(emLargura(
      160,
      const Row(
        children: [ChipFoguinho(dias: 365, compacto: true)],
      ),
      escala: 1.6,
    ));

    expect(find.text('365'), findsOneWidget);
  });

  testWidgets('modo normal escreve a frase completa', (tester) async {
    await tester.pumpWidget(emLargura(300, const ChipFoguinho(dias: 1)));
    expect(find.text('Há 1 dia em 1º lugar'), findsOneWidget);

    await tester.pumpWidget(emLargura(300, const ChipFoguinho(dias: 12)));
    expect(find.text('Há 12 dias em 1º lugar'), findsOneWidget);
  });
}
