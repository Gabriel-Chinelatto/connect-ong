import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/preferencia.dart';
import 'api_service.dart';

/// Servico das preferencias/configuracoes do usuario (aparencia,
/// notificacoes, privacidade, etc.): obtem (GET /usuarios/{id}/preferencias,
/// o backend cria os padroes na primeira chamada) e salva
/// (PUT /usuarios/{id}/preferencias).
class PreferenciaService {
  // Busca as preferencias do usuario (o backend cria os padroes na 1a vez).
  Future<Preferencia> obter(int usuarioId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/preferencias'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar preferências');
    }
    return Preferencia.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  // Salva as preferencias do usuario.
  Future<void> salvar(int usuarioId, Preferencia prefs) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/preferencias'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode(prefs.toJson()),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao salvar preferências');
    }
  }
}
