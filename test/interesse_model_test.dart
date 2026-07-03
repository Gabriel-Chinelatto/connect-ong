import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/interesse.dart';

void main() {
  group('Interesse.fromJson', () {
    test('le um interesse CONCLUIDO com dataConclusao (contrato novo)', () {
      final i = Interesse.fromJson({
        'id': 7,
        'status': 'CONCLUIDO',
        'necessidadeId': 3,
        'necessidadeTitulo': 'Cestas básicas',
        'ongId': 2,
        'ongNome': 'Lar Esperança',
        'dataConclusao': '2026-07-01T14:30:00',
      });

      expect(i.status, 'CONCLUIDO');
      expect(i.dataConclusao, '2026-07-01T14:30:00');
      expect(i.necessidadeTitulo, 'Cestas básicas');
    });

    test('backend antigo (sem dataConclusao) degrada para null', () {
      final i = Interesse.fromJson({'id': 1, 'status': 'ACEITO'});
      expect(i.dataConclusao, isNull);
      expect(i.status, 'ACEITO');
    });
  });
}
