import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prestacao.dart';
import 'api_service.dart';

class PrestacaoService {
  // Lista as prestacoes de contas de um match (mais recentes primeiro).
  Future<List<Prestacao>> listar(int interesseId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/prestacoes?interesseId=$interesseId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar prestações de contas');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((j) => Prestacao.fromJson(j)).toList();
  }
}
