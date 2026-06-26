import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/atividade.dart';

void main() {
  group('Atividade.fromJson', () {
    test('le os campos da resposta da API', () {
      final atividade = Atividade.fromJson({
        'id': 12,
        'tipo': 'CAMPANHA',
        'descricao': 'A campanha "Natal Solidario" atingiu a meta!',
        'ongId': 4,
        'ongNome': 'Lar Viva',
        'dataCriacao': '2026-06-26T14:30:00',
      });

      expect(atividade.id, 12);
      expect(atividade.tipo, 'CAMPANHA');
      expect(atividade.descricao, 'A campanha "Natal Solidario" atingiu a meta!');
      expect(atividade.ongId, 4);
      expect(atividade.ongNome, 'Lar Viva');
      expect(atividade.dataCriacao, '2026-06-26T14:30:00');
    });

    test('usa defaults quando campos vem nulos', () {
      final atividade = Atividade.fromJson({
        'id': null,
        'tipo': null,
        'descricao': null,
        'ongId': null,
        'ongNome': null,
        'dataCriacao': null,
      });

      expect(atividade.id, 0);
      expect(atividade.tipo, '');
      expect(atividade.descricao, '');
      expect(atividade.ongId, isNull);
      expect(atividade.ongNome, isNull);
      expect(atividade.dataCriacao, isNull);
    });
  });
}
