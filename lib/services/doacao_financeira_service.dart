import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class DoacaoFinanceiraService {
  // Faz a doacao (PIX simulado) e retorna o comprovante.
  Future<Map<String, dynamic>> doar({
    required int ongId,
    required int doadorId,
    required double valor,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/doacoes-financeiras'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ongId': ongId,
        'doadorId': doadorId,
        'valor': valor,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao processar a doação');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
