import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/avaliacao.dart';
import 'api_service.dart';

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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ongId': ongId,
        'doadorId': doadorId,
        'nota': nota,
        'comentario': comentario,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao enviar avaliação');
    }
  }

  // Lista as avaliacoes de uma ONG.
  Future<List<Avaliacao>> listar(int ongId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/avaliacoes?ongId=$ongId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar avaliações');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((j) => Avaliacao.fromJson(j)).toList();
  }
}
