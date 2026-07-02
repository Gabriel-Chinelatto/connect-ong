import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mensagem.dart';
import 'api_service.dart';

/// Servico do chat de um match: lista (GET /mensagens?interesseId=) e envia
/// (POST /mensagens) mensagens trocadas entre doador e ONG. O chat so existe
/// apos a ONG aceitar o interesse, por isso toda mensagem referencia o
/// interesseId (id do match).
class MensagemService {
  // Lista as mensagens de um match (ordenadas por data).
  Future<List<Mensagem>> listar(int interesseId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/mensagens?interesseId=$interesseId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar mensagens');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => Mensagem.fromJson(json)).toList();
  }

  // Envia uma mensagem no chat do match.
  Future<void> enviar({
    required int interesseId,
    required String remetente,
    required String conteudo,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/mensagens'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'interesseId': interesseId,
        'remetente': remetente,
        'conteudo': conteudo,
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
}
