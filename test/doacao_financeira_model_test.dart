import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/doacao_financeira.dart';

void main() {
  group('DoacaoFinanceira.fromJson', () {
    test('le os campos da resposta da API (GET /doacoes-financeiras)', () {
      final d = DoacaoFinanceira.fromJson({
        'id': 3,
        'ongId': 7,
        'ongNome': 'Lar Feliz',
        'doadorNome': 'Maria',
        'valor': 150.5,
        'codigoPix': '00020126SIMULADOXXX',
        'status': 'CONCLUIDA',
        'dataCriacao': '2026-07-02T15:30:00',
      });

      expect(d.id, 3);
      expect(d.ongId, 7);
      expect(d.ongNome, 'Lar Feliz');
      expect(d.valor, 150.5);
      expect(d.status, 'CONCLUIDA');
      expect(d.dataCriacao, DateTime(2026, 7, 2, 15, 30));
    });

    test('aceita valor inteiro (JSON num) e converte para double', () {
      final d = DoacaoFinanceira.fromJson({
        'id': 1,
        'ongNome': 'ONG',
        'valor': 50,
        'status': 'CONCLUIDA',
      });

      expect(d.valor, 50.0);
      expect(d.valor, isA<double>());
    });

    test('usa defaults quando campos vem nulos', () {
      final d = DoacaoFinanceira.fromJson({'id': 2});

      expect(d.ongNome, 'ONG');
      expect(d.valor, 0);
      expect(d.status, '');
      expect(d.dataCriacao, isNull);
      expect(d.dataFormatada, '—');
    });

    test('formata valor e data no padrao brasileiro', () {
      final d = DoacaoFinanceira.fromJson({
        'id': 4,
        'ongNome': 'ONG',
        'valor': 1234.5,
        'status': 'CONCLUIDA',
        'dataCriacao': '2026-01-09T08:05:00',
      });

      expect(d.valorFormatado, 'R\$ 1234,50');
      expect(d.dataFormatada, '09/01/2026');
    });
  });
}
