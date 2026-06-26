import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/ong.dart';

void main() {
  group('Ong.fromJson', () {
    test('le os campos da resposta da API', () {
      final ong = Ong.fromJson({
        'id': 7,
        'nome': 'Lar Feliz',
        'email': 'contato@larfeliz.org',
        'telefone': '199999-0000',
        'cidade': 'Limeira',
        'descricao': 'Acolhe criancas',
        'verificada': true,
      });

      expect(ong.id, 7);
      expect(ong.nome, 'Lar Feliz');
      expect(ong.cidade, 'Limeira');
      expect(ong.verificada, true);
    });

    test('usa defaults quando campos vem nulos', () {
      final ong = Ong.fromJson({'id': null});

      expect(ong.id, isNull);
      expect(ong.nome, '');
      expect(ong.verificada, false);
    });
  });
}
