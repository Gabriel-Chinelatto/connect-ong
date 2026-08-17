import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/pages/cadastro_doador_page.dart';

/// Guarda de saída no cadastro multi-passo do doador.
///
/// Regra: qualquer campo preenchido + cadastro não concluído → avisa antes
/// de descartar. Sem "Salvar" (não faz sentido salvar cadastro parcial).
void main() {
  Widget cenario() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CadastroDoadorPage()),
            ),
            child: const Text('abrir cadastro'),
          ),
        ),
      ),
    );
  }

  Future<void> abrirCadastro(WidgetTester tester) async {
    await tester.pumpWidget(cenario());
    await tester.tap(find.text('abrir cadastro'));
    await tester.pumpAndSettle();
  }

  testWidgets('sem digitar nada, o Voltar sai direto (não incomoda)',
      (tester) async {
    await abrirCadastro(tester);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Alterações não salvas'), findsNothing);
    expect(find.text('abrir cadastro'), findsOneWidget,
        reason: 'deve ter voltado à tela anterior');
  });

  testWidgets('digitou o nome e tentou voltar → aparece o aviso, sem "Salvar"',
      (tester) async {
    await abrirCadastro(tester);

    // Digita no primeiro campo (Nome completo) e tenta sair.
    await tester.enterText(find.byType(TextField).first, 'Maria da Silva');
    await tester.pump();
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Alterações não salvas'), findsOneWidget);
    // Cadastro parcial não oferece "Salvar" — só Descartar/Continuar.
    expect(find.text('Salvar'), findsNothing);
    expect(find.text('Criar conta'), findsOneWidget,
        reason: 'ainda não pode ter saído do cadastro');
  });

  testWidgets('"Descartar" abandona o cadastro; "Continuar editando" fica',
      (tester) async {
    await abrirCadastro(tester);
    await tester.enterText(find.byType(TextField).first, 'Maria da Silva');
    await tester.pump();

    // Primeiro escolhe continuar: permanece no cadastro.
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.text('Criar conta'), findsOneWidget);

    // Depois descarta: volta à tela anterior.
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('abrir cadastro'), findsOneWidget);
  });
}
