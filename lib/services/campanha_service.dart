import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/campanha.dart';
import 'api_service.dart';

class CampanhaService {
  static const String _base = '${ApiService.baseUrl}/campanhas';

  /// Lista as campanhas abertas (nao encerradas).
  Future<List<Campanha>> listarAbertas() async {
    final response = await http.get(Uri.parse('$_base?abertas=true'),
        headers: ApiService.authHeaders());
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Campanha.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar campanhas');
  }

  /// Contribui com um valor para a campanha; retorna a campanha atualizada.
  Future<Campanha> contribuir({
    required int campanhaId,
    required double valor,
    String? doadorNome,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/$campanhaId/contribuir'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({'valor': valor, 'doadorNome': doadorNome}),
    );
    if (response.statusCode == 200) {
      return Campanha.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    final corpo = jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception(corpo['erro'] ?? 'Erro ao contribuir');
  }
}
