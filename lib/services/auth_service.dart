import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {

  // CHROME / WINDOWS
  static const String baseUrl =
      'http://localhost:8080';

  // ANDROID EMULATOR
  // static const String baseUrl =
  //     'http://10.0.2.2:8080';

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

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

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