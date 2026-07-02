import 'dart:convert';

import 'package:http/http.dart' as http;

import '../doacao.dart';
import 'api_service.dart';

/// Servico CRUD de doacoes de itens (nao financeiras) sobre /doacoes:
/// listar (GET), cadastrar (POST), atualizar (PUT /doacoes/{id}) e excluir
/// (DELETE /doacoes/{id}, espera 204 No Content).
class DoacaoService {

  static const String baseUrl = ApiService.baseUrl;

  /// Lista as doacoes do PROPRIO doador (o backend filtra pelo token).
  Future<List<Doacao>> listarDoacoes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/doacoes/minhas'),
      headers: ApiService.authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao carregar doações',
      );
    }

    final List<dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes));

    return data
        .map(
          (json) => Doacao.fromJson(json),
        )
        .toList();
  }

  Future<void> cadastrarDoacao(
    Doacao doacao,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doacoes'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode(
        doacao.toJson(),
      ),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Erro ao cadastrar doação',
      );
    }
  }

  Future<void> atualizarDoacao(
    Doacao doacao,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/doacoes/${doacao.id}',
      ),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode(
        doacao.toJson(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao atualizar doação',
      );
    }
  }

  Future<void> excluirDoacao(
    int id,
  ) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/doacoes/$id',
      ),
      headers: ApiService.authHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Erro ao excluir doação',
      );
    }
  }
}