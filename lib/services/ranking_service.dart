import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ranking_ong.dart';
import 'api_service.dart';

class RankingService {
  /// Lista o ranking de transparencia das ONGs ordenado por score desc
  /// (GET /publico/ranking?limite=$limite).
  Future<List<RankingOng>> listar({int limite = 20}) async {
    final response = await http
        .get(Uri.parse('${ApiService.baseUrl}/publico/ranking?limite=$limite'));
    if (response.statusCode == 200) {
      final raw = jsonDecode(utf8.decode(response.bodyBytes));
      if (raw is List) {
        return raw
            .map((e) => RankingOng.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <RankingOng>[];
    }
    throw Exception('Erro ao carregar o ranking de transparencia');
  }
}
