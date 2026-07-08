import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/services/assistente_service.dart';

void main() {
  group('RespostaAssistente.fromJson', () {
    test('le uma resposta completa com sugestoes (contrato do backend)', () {
      final r = RespostaAssistente.fromJson({
        'resposta': 'Perto de voce ha estas ONGs:',
        'modo': 'ia',
        'sugestoes': [
          {
            'tipo': 'ONG',
            'id': 12,
            'titulo': 'Lar Esperanca',
            'subtitulo': 'Sorocaba - SP',
          },
          {
            'tipo': 'NECESSIDADE',
            'id': 45,
            'titulo': 'Cestas basicas',
            'subtitulo': 'Casa do Caminho',
          },
        ],
      });

      expect(r.resposta, 'Perto de voce ha estas ONGs:');
      expect(r.modo, 'ia');
      expect(r.modoRegras, isFalse);
      expect(r.sugestoes, hasLength(2));

      final ong = r.sugestoes[0];
      expect(ong.ehOng, isTrue);
      expect(ong.ehNecessidade, isFalse);
      expect(ong.id, 12);
      expect(ong.titulo, 'Lar Esperanca');

      final nec = r.sugestoes[1];
      expect(nec.ehNecessidade, isTrue);
      expect(nec.id, 45);
    });

    test('modo "regras" liga o selo de modo basico', () {
      final r = RespostaAssistente.fromJson({
        'resposta': 'Resposta basica.',
        'modo': 'regras',
      });
      expect(r.modoRegras, isTrue);
      expect(r.sugestoes, isEmpty);
    });

    test('resposta minima (sem sugestoes/modo) degrada graciosamente', () {
      final r = RespostaAssistente.fromJson({'resposta': 'Ola!'});
      expect(r.resposta, 'Ola!');
      expect(r.sugestoes, isEmpty);
      expect(r.modo, 'ia'); // default
      expect(r.modoRegras, isFalse);
    });

    test('sugestao sem titulo e descartada (nao vira card vazio)', () {
      final r = RespostaAssistente.fromJson({
        'resposta': 'x',
        'sugestoes': [
          {'tipo': 'ONG', 'id': 1, 'titulo': '', 'subtitulo': 's'},
          {'tipo': 'ong', 'id': 2, 'titulo': 'Valida', 'subtitulo': 's'},
        ],
      });
      expect(r.sugestoes, hasLength(1));
      // tipo normalizado para maiusculas.
      expect(r.sugestoes.single.tipo, 'ONG');
      expect(r.sugestoes.single.ehOng, isTrue);
    });

    test('id ausente vira null (UI degrada, nao navega)', () {
      final s = SugestaoAssistente.fromJson({
        'tipo': 'NECESSIDADE',
        'titulo': 'Sem id',
        'subtitulo': 's',
      });
      expect(s.id, isNull);
      expect(s.ehNecessidade, isTrue);
    });
  });
}
