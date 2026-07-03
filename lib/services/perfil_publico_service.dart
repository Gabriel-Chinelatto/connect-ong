import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/perfil_publico_doador.dart';
import '../models/perfil_publico_ong.dart';
import 'api_service.dart';

/// Servico dos perfis PÚBLICOS: o de uma ONG (GET /ongs/{id}/perfil-publico)
/// e o de um doador (GET /usuarios/{id}/perfil-publico), ambos exibidos como
/// "páginas" públicas dentro do app.
class PerfilPublicoService {
  static const String _base = '${ApiService.baseUrl}/ongs';

  /// Busca o perfil publico completo de uma ONG (GET /ongs/{id}/perfil-publico).
  Future<PerfilPublicoOng> buscar(int ongId) async {
    final response = await http.get(Uri.parse('$_base/$ongId/perfil-publico'),
        headers: ApiService.authHeaders()).timeout(ApiService.timeout);
    if (response.statusCode == 200) {
      return PerfilPublicoOng.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Erro ao carregar o perfil da ONG');
  }

  /// Busca o perfil público de um DOADOR (GET /usuarios/{id}/perfil-publico).
  /// O backend devolve 404 quando o usuário não existe ou foi excluído.
  Future<PerfilPublicoDoador> buscarDoador(int usuarioId) async {
    final response = await http
        .get(
          Uri.parse(
              '${ApiService.baseUrl}/usuarios/$usuarioId/perfil-publico'),
          headers: ApiService.authHeaders(),
        )
        .timeout(ApiService.timeout);
    if (response.statusCode == 200) {
      return PerfilPublicoDoador.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    if (response.statusCode == 404) {
      throw Exception('Perfil não encontrado');
    }
    throw Exception('Erro ao carregar o perfil do doador');
  }
}
