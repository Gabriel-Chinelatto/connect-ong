import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/widgets/forms/seletor_uf_cidade.dart';

/// Testes puros das funções do seletor Estado→Cidade (sem rootBundle nem
/// widgets): normalização de acentos e filtro de cidades com lista injetada.
void main() {
  group('semAcento', () {
    test('remove acentos comuns de nomes de municípios', () {
      expect(semAcento('São Paulo'), 'Sao Paulo');
      expect(semAcento('Brasília'), 'Brasilia');
      expect(semAcento('Paraná'), 'Parana');
      expect(semAcento('Açaí'), 'Acai');
      expect(semAcento('Itapecerica da Serra'), 'Itapecerica da Serra');
    });

    test('preserva maiúsculas/minúsculas e demais caracteres', () {
      expect(semAcento('ÂNGULO'), 'ANGULO');
      expect(semAcento("Sant'Ana do Livramento"), "Sant'Ana do Livramento");
      expect(semAcento(''), '');
    });
  });

  group('filtrarCidades', () {
    const cidades = [
      'Mogi das Cruzes',
      'Mogi Guaçu',
      'Santos',
      'São Paulo',
      'São José dos Campos',
      'Taubaté',
    ];

    test('"sao" (sem acento, minúsculo) encontra "São Paulo"', () {
      final resultado = filtrarCidades(cidades, 'sao');
      expect(resultado, contains('São Paulo'));
      expect(resultado, contains('São José dos Campos'));
      expect(resultado, isNot(contains('Santos')));
    });

    test('"MOGI" (maiúsculo) encontra "Mogi das Cruzes"', () {
      final resultado = filtrarCidades(cidades, 'MOGI');
      expect(resultado, ['Mogi das Cruzes', 'Mogi Guaçu']);
    });

    test('busca por "contém", não só prefixo', () {
      expect(filtrarCidades(cidades, 'campos'), ['São José dos Campos']);
    });

    test('termo com acento também encontra ("guaçu" e "guacu")', () {
      expect(filtrarCidades(cidades, 'guaçu'), ['Mogi Guaçu']);
      expect(filtrarCidades(cidades, 'guacu'), ['Mogi Guaçu']);
    });

    test('termo vazio (ou só espaços) devolve a lista inteira', () {
      expect(filtrarCidades(cidades, ''), cidades);
      expect(filtrarCidades(cidades, '   '), cidades);
    });

    test('termo sem correspondência devolve lista vazia', () {
      expect(filtrarCidades(cidades, 'xyz'), isEmpty);
    });
  });
}
