import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Servico de doacao financeira (PIX simulado): envia o valor doado pelo
/// doador a uma ONG (POST /doacoes-financeiras) e retorna o comprovante da
/// transacao.
class DoacaoFinanceiraService {
  // Faz a doacao (PIX simulado) e retorna o comprovante.
  Future<Map<String, dynamic>> doar({
    required int ongId,
    required int doadorId,
    required double valor,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/doacoes-financeiras'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'ongId': ongId,
        'doadorId': doadorId,
        'valor': valor,
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
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
