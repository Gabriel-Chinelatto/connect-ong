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

      return jsonDecode(
        response.body,
      );
    }

    final body = jsonDecode(
      response.body,
    );

    throw Exception(

      body['erro'] ??
          'Erro ao realizar login',
    );
  }
}