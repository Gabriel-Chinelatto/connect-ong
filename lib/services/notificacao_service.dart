import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notificacao.dart';
import 'api_service.dart';

/// Servico de notificacoes do usuario: lista as notificacoes
/// (GET /notificacoes?usuarioId=), conta as nao lidas para o badge
/// (GET /notificacoes/nao-lidas, retorna 0 em qualquer falha) e marca todas
/// como lidas (PUT /notificacoes/marcar-todas).
class NotificacaoService {
  Future<List<Notificacao>> listar(int usuarioId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/notificacoes?usuarioId=$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar notificações');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((j) => Notificacao.fromJson(j)).toList();
  }

  Future<int> contarNaoLidas(int usuarioId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiService.baseUrl}/notificacoes/nao-lidas?usuarioId=$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) return 0;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return (body['naoLidas'] ?? 0) as int;
  }

  Future<void> marcarTodas(int usuarioId) async {
    await http.put(
      Uri.parse(
          '${ApiService.baseUrl}/notificacoes/marcar-todas?usuarioId=$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
  }

  // Marca UMA notificação como lida (PUT /notificacoes/{id}/lida). O backend
  // confere o dono pelo token.
  Future<void> marcarLida(int id) async {
    await http.put(
      Uri.parse('${ApiService.baseUrl}/notificacoes/$id/lida'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
  }
}
