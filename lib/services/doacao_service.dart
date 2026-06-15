import 'dart:convert';

import 'package:http/http.dart' as http;

import '../doacao.dart';

class DoacaoService {
  // CHROME / WINDOWS
  static const String baseUrl =
      'http://localhost:8080';

  // ANDROID EMULATOR
  // static const String baseUrl =
  //     'http://10.0.2.2:8080';

  Future<List<Doacao>> listarDoacoes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/doacoes'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao carregar doações',
      );
    }

    final List<dynamic> data =
        jsonDecode(response.body);

    return data
        .map(
          (json) => Doacao.fromJson(json),
        )
        .toList();
  }

  Future<void> cadastrarDoacao(
    Doacao doacao,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doacoes'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        doacao.toJson(),
      ),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Erro ao cadastrar doação',
      );
    }
  }

  Future<void> atualizarDoacao(
    Doacao doacao,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/doacoes/${doacao.id}',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        doacao.toJson(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao atualizar doação',
      );
    }
  }

  Future<void> excluirDoacao(
    int id,
  ) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/doacoes/$id',
      ),
    );

    if (response.statusCode != 204) {
      throw Exception(
        'Erro ao excluir doação',
      );
    }
  }
}