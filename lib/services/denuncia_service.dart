import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Servico de moderacao: registra denuncias de conteudo/conduta (POST
/// /denuncias) contra um alvo (tipoAlvo + alvoId). O denuncianteId e
/// opcional para permitir denuncia anonima; campos vazios sao omitidos do
/// corpo.
class DenunciaService {
  // Cria uma denuncia (POST /denuncias).
  // denuncianteId e opcional (null = anonimo).
  Future<void> criar({
    int? denuncianteId,
    required String tipoAlvo,
    required int alvoId,
    required String motivo,
    String? descricao,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/denuncias'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        if (denuncianteId != null) 'denuncianteId': denuncianteId,
        'tipoAlvo': tipoAlvo,
        'alvoId': alvoId,
        'motivo': motivo,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erro ao enviar denuncia');
    }
  }
}
