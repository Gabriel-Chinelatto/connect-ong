import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/utils/categorias.dart';

void main() {
  group('Categorias.normalizar', () {
    test('mapeia valores legados (singular/acento/caixa) para o canonico', () {
      expect(Categorias.normalizar('Alimento'), 'Alimentos');
      expect(Categorias.normalizar('alimentos'), 'Alimentos');
      expect(Categorias.normalizar('Roupa'), 'Roupas');
      expect(Categorias.normalizar('Educação'), 'Educacao');
      expect(Categorias.normalizar('educacao'), 'Educacao');
      expect(Categorias.normalizar('Saúde'), 'Saude');
      expect(Categorias.normalizar('BRINQUEDO'), 'Brinquedos');
      expect(Categorias.normalizar('Higiene'), 'Higiene');
    });

    test('valores desconhecidos voltam com trim, sem rejeicao', () {
      expect(Categorias.normalizar('  Móveis '), 'Móveis');
      expect(Categorias.normalizar(''), '');
    });
  });

  group('Categorias.rotulo e icone', () {
    test('rotulo exibe com acento a partir do valor canonico ou legado', () {
      expect(Categorias.rotulo('Educacao'), 'Educação');
      expect(Categorias.rotulo('saude'), 'Saúde');
      expect(Categorias.rotulo('Alimento'), 'Alimentos');
      expect(Categorias.rotulo('Categoria X'), 'Categoria X');
    });

    test('icone tem fallback generico para desconhecidos', () {
      expect(Categorias.icone('Alimentos'), Icons.restaurant_outlined);
      expect(Categorias.icone('desconhecida'), Icons.category_outlined);
    });
  });
}
