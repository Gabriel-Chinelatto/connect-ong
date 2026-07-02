import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Servico do perfil do proprio usuario logado: obtem
/// (GET /usuarios/{id}/perfil) e atualiza (PUT /usuarios/{id}/perfil) os
/// dados cadastrais, alem de alterar a senha (PUT /usuarios/{id}/senha),
/// que exige a senha atual para confirmacao.
class PerfilService {
  // Obter o perfil do usuario.
  Future<Map<String, dynamic>> obter(int usuarioId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/perfil'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar perfil');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  // Atualizar o perfil.
  Future<Map<String, dynamic>> atualizar(
    int usuarioId,
    Map<String, dynamic> dados,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/perfil'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode(dados),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao salvar perfil');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  // Alterar a senha.
  Future<void> alterarSenha(
    int usuarioId,
    String senhaAtual,
    String novaSenha,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/senha'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({'senhaAtual': senhaAtual, 'novaSenha': novaSenha}),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      String msgErro;
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        msgErro = (body is Map && body['erro'] != null)
            ? body['erro'].toString()
            : 'Erro (HTTP ${response.statusCode})';
      } catch (_) {
        msgErro = 'Erro (HTTP ${response.statusCode})';
      }
      throw Exception(msgErro);
    }
  }
}
