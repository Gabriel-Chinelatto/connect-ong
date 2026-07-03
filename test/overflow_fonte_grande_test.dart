import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/doador/dashboard_impacto_screen.dart';
import 'package:flutter_application_1/doador/meus_matches_screen.dart';
import 'package:flutter_application_1/models/campanha.dart';
import 'package:flutter_application_1/widgets/cards/carrossel_campanhas.dart';

/// Varredura anti-overflow: telas/widgets principais em TELA ESTREITA (320px)
/// com FONTE GRANDE (textScaler 1.3 e 1.6). Um RenderFlex overflow vira
/// exceção no teste — o que reproduz os bugs reais dos screenshots (barra de
/// busca +3.6px, grid do Meu Impacto +9.7px) e trava regressões.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget comEscala(Widget tela, double escala) {
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: tela,
    );
  }

  Future<void> telaEstreita(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  for (final escala in [1.3, 1.6]) {
    testWidgets('Meu Impacto não estoura com fonte $escala', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await telaEstreita(tester);
      await tester.pumpWidget(
          comEscala(DashboardImpactoScreen(onIrParaAba: (_, [_]) {}), escala));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Matches realizados'), findsOneWidget);
    });

    testWidgets('Meus Matches (3 abas) não estoura com fonte $escala',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await telaEstreita(tester);
      await tester.pumpWidget(comEscala(const MeusMatchesScreen(), escala));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Concluídas'), findsOneWidget);
    });

    testWidgets('Carrossel de campanhas não estoura com fonte $escala',
        (tester) async {
      await telaEstreita(tester);
      final campanhas = [
        Campanha(
          id: 1,
          titulo: 'Campanha com um título bem longo para forçar duas linhas',
          descricao: 'desc',
          metaValor: 1000,
          valorArrecadado: 350,
          progresso: 35,
          encerrada: false,
          destaque: true,
          categoria: 'Alimentos',
          ongId: 1,
          ongNome: 'ONG com nome também bastante comprido',
        ),
        Campanha(
          id: 2,
          titulo: 'Outra campanha',
          descricao: 'desc',
          metaValor: 500,
          valorArrecadado: 500,
          progresso: 100,
          encerrada: false,
          destaque: false,
          categoria: 'Saude',
          ongId: 2,
          ongNome: 'ONG 2',
        ),
      ];
      await tester.pumpWidget(comEscala(
        Scaffold(
          body: CarrosselCampanhas(
            campanhas: campanhas,
            altura: 216 * escala, // como a Início faz via fatorFonte
            onTap: (_) {},
          ),
        ),
        escala,
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      // Desmonta para cancelar o Timer do auto-avanço.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
