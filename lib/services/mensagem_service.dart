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

  // Presenca do OUTRO participante (online, ultimoVisto, digitando). Chamar
  // tambem registra a MINHA presenca (heartbeat). Best-effort: NUNCA quebra o
  // chat — em qualquer erro/timeout ou status != 200 devolve um default seguro.
  Future<Map<String, dynamic>> status(int interesseId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiService.baseUrl}/mensagens/status?interesseId=$interesseId'),
        headers: ApiService.authHeaders(),
      ).timeout(ApiService.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (_) {
      // ignorado: presenca e best-effort.
    }
    return {'online': false, 'ultimoVisto': null, 'digitando': false};
  }

  // Sinaliza que o usuario esta digitando. Best-effort: erros sao ignorados.
  Future<void> digitando(int interesseId) async {
    try {
      await http.post(
        Uri.parse(
            '${ApiService.baseUrl}/mensagens/digitando?interesseId=$interesseId'),
        headers: ApiService.jsonHeaders(),
      ).timeout(ApiService.timeout);
    } catch (_) {
      // ignorado: heartbeat de digitacao e best-effort.
    }
  }
}
