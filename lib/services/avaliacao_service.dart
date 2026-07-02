import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/avaliacao.dart';
import 'api_service.dart';

/// Servico de avaliacoes de ONGs feitas pelo doador: registra nota e
/// comentario (POST /avaliacoes, faz upsert por doador+ONG) e lista as
/// avaliacoes de uma ONG (GET /avaliacoes?ongId=).
class AvaliacaoService {
  // Doador avalia uma ONG (cria ou atualiza).
  Future<void> avaliar({
    required int ongId,
    required int doadorId,
    required int nota,
    required String comentario,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/avaliacoes'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'ongId': ongId,
        'doadorId': doadorId,
        'nota': nota,
        'comentario': comentario,
      }),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao enviar avaliação');
    }
  }

  // Lista as avaliacoes de uma ONG.
  Future<List<Avaliacao>> listar(int ongId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/avaliacoes?ongId=$ongId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar avaliações');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((j) => Avaliacao.fromJson(j)).toList();
  }
}
