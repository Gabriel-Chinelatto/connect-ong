import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/atividade.dart';
import 'api_service.dart';

class AtividadeService {
  static const String _base = '${ApiService.baseUrl}/atividades';

  /// Lista as atividades recentes da plataforma (feed global), ordenadas por
  /// dataCriacao desc.
  Future<List<Atividade>> listarRecentes({int limit = 30}) async {
    final response = await http.get(Uri.parse('$_base?limit=$limit'),
        headers: ApiService.authHeaders());
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Atividade.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar atividades');
  }
}
