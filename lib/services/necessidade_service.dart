import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/necessidade.dart';
import 'api_service.dart';

/// Servico das necessidades publicadas pelas ONGs: alimenta o feed principal
/// do doador listando apenas as necessidades em aberto
/// (GET /necessidades?status=ABERTA), que sao o ponto de partida do match.
class NecessidadeService {
  // Lista as necessidades abertas (feed do doador).
  Future<List<Necessidade>> listarAbertas() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/necessidades?status=ABERTA'),
      headers: ApiService.authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar necessidades');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

    return data.map((json) => Necessidade.fromJson(json)).toList();
  }
}
