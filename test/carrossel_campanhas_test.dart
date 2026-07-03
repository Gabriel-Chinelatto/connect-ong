import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/campanha.dart';
import 'package:flutter_application_1/widgets/cards/carrossel_campanhas.dart';
import 'package:flutter_application_1/widgets/feedback/celebracao.dart';

Campanha _campanha(int id, String titulo) => Campanha(
      id: id,
      titulo: titulo,
      descricao: 'desc',
      metaValor: 100,
      valorArrecadado: 40,
      progresso: 40,
      encerrada: false,
      destaque: id == 1,
      categoria: 'Alimentos',
      ongId: 1,
      ongNome: 'ONG Teste',
    );

void main() {
  testWidgets('CarrosselCampanhas auto-avança a página após 5s',
      (tester) async {
    final campanhas = [
      _campanha(1, 'Campanha A'),
      _campanha(2, 'Campanha B'),
      _campanha(3, 'Campanha C'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CarrosselCampanhas(
          campanhas: campanhas,
          altura: 216,
          onTap: (_) {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 950)); // barra animada

    // Indicador: a "pílula" (largura 18) começa na primeira bolinha.
    List<double?> largurasDots() => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((w) => (w.constraints)?.maxWidth)
        .toList();
    expect(largurasDots().first, 18);

    // Após o intervalo de 5s + transição, avança para a segunda página.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 600));
    final leituras = largurasDots();
    expect(leituras[0], 7);
    expect(leituras[1], 18);

    // Desmonta para cancelar o Timer (sem timers pendentes no teste).
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('CarrosselCampanhas com UMA campanha não cria auto-avanço',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CarrosselCampanhas(
          campanhas: [_campanha(1, 'Única')],
          altura: 216,
          onTap: (_) {},
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Única'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('CelebracaoSucesso anima até o fim sem erros', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: CelebracaoSucesso(tamanho: 150))),
    ));
    // Percorre a animação inteira (2.2s) em passos.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
