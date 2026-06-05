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

  Future<void> cadastrarDoacao(
    Doacao doacao,
  ) async {

    final response = await http.post(

      Uri.parse(
        '$baseUrl/doacoes',
      ),

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({

        'nome': doacao.nome,

        'descricao':
            doacao.descricao,

        'quantidade':
            doacao.quantidade,

        'categoria':
            doacao.categoria,

        'tipo':
            doacao.tipo,

        'urgente':
            doacao.urgente,

        'novo':
            doacao.novo,
      }),
    );

    print(response.statusCode);

    print(response.body);

    if (response.statusCode != 200) {

      throw Exception(
        'Erro ao cadastrar doação',
      );
    }
  }
}