import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/utils/frases_home.dart';

void main() {
  group('FrasesHome', () {
    test('tem pelo menos 20 frases, todas preenchidas e sem duplicatas', () {
      expect(FrasesHome.frases.length, greaterThanOrEqualTo(20));
      for (final f in FrasesHome.frases) {
        expect(f.trim(), isNotEmpty);
      }
      expect(FrasesHome.frases.toSet().length, FrasesHome.frases.length,
          reason: 'frases duplicadas empobrecem o sorteio');
    });

    test('daSessao pertence à lista e é estável durante a sessão', () {
      final primeira = FrasesHome.daSessao;
      expect(FrasesHome.frases, contains(primeira));
      // Lida como campo estático: não muda entre leituras na mesma execução.
      expect(FrasesHome.daSessao, primeira);
    });
  });
}
