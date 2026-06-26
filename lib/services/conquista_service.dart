import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/conquista.dart';
import 'api_service.dart';

class ConquistaService {
  static const String _base = '${ApiService.baseUrl}/conquistas';

  /// Lista as conquistas do doador (conquistadas e bloqueadas).
  Future<List<Conquista>> doador(int usuarioId) async {
    final response = await http.get(Uri.parse('$_base/doador/$usuarioId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Conquista.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar conquistas');
  }
}
