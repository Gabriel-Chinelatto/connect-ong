import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/favorito.dart';
import 'api_service.dart';

/// Servico de favoritos do doador (ONGs e campanhas) sobre /favoritos:
/// lista os favoritos (GET), retorna apenas os alvoIds de um tipo para
/// marcar a UI (GET /favoritos/ids), adiciona de forma idempotente (POST)
/// e remove (DELETE por usuarioId+tipo+alvoId).
class FavoritoService {
  static const String _base = '${ApiService.baseUrl}/favoritos';

  /// Lista todos os favoritos do usuario.
  Future<List<Favorito>> listar(int usuarioId) async {
    final response =
        await http.get(Uri.parse('$_base?usuarioId=$usuarioId'),
            headers: ApiService.authHeaders()).timeout(ApiService.timeout);
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Favorito.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar favoritos');
  }

  /// Retorna o conjunto de alvoIds favoritados de um determinado tipo.
  Future<Set<int>> ids(int usuarioId, String tipo) async {
    final response = await http
        .get(Uri.parse('$_base/ids?usuarioId=$usuarioId&tipo=$tipo'),
            headers: ApiService.authHeaders()).timeout(ApiService.timeout);
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => (e as num).toInt()).toSet();
    }
    throw Exception('Erro ao carregar favoritos');
  }

  /// Adiciona um favorito (idempotente).
  Future<void> adicionar(int usuarioId, String tipo, int alvoId) async {
    final response = await http.post(
      Uri.parse(_base),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'usuarioId': usuarioId,
        'tipo': tipo,
        'alvoId': alvoId,
      }),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao favoritar');
    }
  }

  /// Remove um favorito.
  Future<void> remover(int usuarioId, String tipo, int alvoId) async {
    final response = await http.delete(
      Uri.parse(
          '$_base?usuarioId=$usuarioId&tipo=$tipo&alvoId=$alvoId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao remover favorito');
    }
  }
}
