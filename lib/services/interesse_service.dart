import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/interesse.dart';
import 'api_service.dart';

/// Servico do fluxo de match (hero feature): o doador demonstra interesse
/// numa necessidade de ONG (POST /interesses) e consulta seus matches
/// (GET /interesses?doadorId=). Quando a ONG aceita o interesse, o match
/// fica habilitado e libera o chat com a ONG.
class InteresseService {
  // Doador demonstra interesse em uma necessidade.
  Future<void> demonstrarInteresse({
    required int necessidadeId,
    required int doadorId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/interesses'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'necessidadeId': necessidadeId,
        'doadorId': doadorId,
      }),
    ).timeout(ApiService.timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      String msgErro;
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        msgErro = (body is Map && body['erro'] != null)
            ? body['erro'].toString()
            : 'Erro (HTTP ${response.statusCode})';
      } catch (_) {
        msgErro = 'Erro (HTTP ${response.statusCode})';
      }
      throw Exception(msgErro);
    }
  }

  // Lista os interesses/matches de um doador.
  Future<List<Interesse>> meusMatches(int doadorId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/interesses?doadorId=$doadorId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar seus matches');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

    return data.map((json) => Interesse.fromJson(json)).toList();
  }
}
