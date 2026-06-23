import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/interesse.dart';
import 'api_service.dart';

class InteresseService {
  // Doador demonstra interesse em uma necessidade.
  Future<void> demonstrarInteresse({
    required int necessidadeId,
    required int doadorId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/interesses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'necessidadeId': necessidadeId,
        'doadorId': doadorId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao demonstrar interesse');
    }
  }

  // Lista os interesses/matches de um doador.
  Future<List<Interesse>> meusMatches(int doadorId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/interesses?doadorId=$doadorId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar seus matches');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

    return data.map((json) => Interesse.fromJson(json)).toList();
  }
}
