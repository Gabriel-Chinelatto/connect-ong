import 'package:flutter/material.dart';

/// Uma categoria canonica de doacao/necessidade.
///
/// [valor] e o que trafega e fica armazenado no backend (sem acento, no
/// plural — igual ao seed e ao GET /categorias da API). [rotulo] e o texto
/// exibido ao usuario (com acento).
class CategoriaInfo {
  final String valor;
  final String rotulo;
  final IconData icone;

  const CategoriaInfo(this.valor, this.rotulo, this.icone);
}

/// Fonte unica de verdade das categorias no mobile (espelha o backend).
///
/// Alem da lista canonica, oferece [normalizar] para casar valores legados
/// (singular, com acento, caixa diferente) com o valor canonico — assim
/// filtros e chips nao duplicam "Alimento" e "Alimentos".
class Categorias {
  Categorias._();

  static const List<CategoriaInfo> todas = [
    CategoriaInfo('Alimentos', 'Alimentos', Icons.restaurant_outlined),
    CategoriaInfo('Roupas', 'Roupas', Icons.checkroom_outlined),
    CategoriaInfo('Higiene', 'Higiene', Icons.clean_hands_outlined),
    CategoriaInfo('Brinquedos', 'Brinquedos', Icons.toys_outlined),
    CategoriaInfo('Educacao', 'Educação', Icons.school_outlined),
    CategoriaInfo('Saude', 'Saúde', Icons.health_and_safety_outlined),
  ];

  /// Mapeia um valor qualquer para o canonico ("alimento" → "Alimentos").
  /// Valores desconhecidos voltam com trim, sem serem rejeitados.
  static String normalizar(String valor) {
    final chave = _chave(valor);
    for (final c in todas) {
      final canonica = _chave(c.valor);
      if (chave == canonica || '${chave}s' == canonica) return c.valor;
    }
    return valor.trim();
  }

  /// Rotulo de exibicao ("Educacao" → "Educação"). Desconhecidos: o proprio valor.
  static String rotulo(String valor) => _busca(valor)?.rotulo ?? valor.trim();

  /// Icone da categoria (fallback generico para valores desconhecidos).
  static IconData icone(String valor) =>
      _busca(valor)?.icone ?? Icons.category_outlined;

  static CategoriaInfo? _busca(String valor) {
    final v = normalizar(valor);
    for (final c in todas) {
      if (c.valor == v) return c;
    }
    return null;
  }

  // Chave de comparacao: minusculas e sem acentos.
  static String _chave(String v) {
    var s = v.trim().toLowerCase();
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    for (var i = 0; i < de.length; i++) {
      s = s.replaceAll(de[i], para[i]);
    }
    return s;
  }
}
