import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class AuthService {

  static const String baseUrl = ApiService.baseUrl;

  Future<Map<String, dynamic>> login({

    required String email,

    required String senha,

  }) async {

    final url = Uri.parse(
      '$baseUrl/usuarios/login',
    );

    final response = await http.post(

      url,

      headers: {
        'Content-Type': 'application/json',
      },

      body: jsonEncode({

        'email': email,

        'senha': senha,
      }),
    );

    if (response.statusCode == 200) {

      final resp = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      // Guarda o accessToken para ser enviado nas próximas requisições.
      await ApiService.setToken(resp['accessToken']);

      return resp;
    }

    final body = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    throw Exception(

      body['erro'] ??
          'Erro ao realizar login',
    );
  }
}