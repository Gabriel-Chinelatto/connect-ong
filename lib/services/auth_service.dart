import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Serviço de autenticação: realiza o login chamando `POST /usuarios/login`.
///
/// Em caso de sucesso (HTTP 200), extrai o `accessToken` (JWT) da resposta e o
/// entrega ao [ApiService] para uso nas requisições subsequentes. Em falha,
/// lança [Exception] com a mensagem de erro retornada pelo backend.
/// O corpo é decodificado via `utf8.decode` para preservar acentuação.
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
    ).timeout(ApiService.timeout);

    if (response.statusCode == 200) {

      final resp = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      // 2FA: o backend pode responder 200 SEM token, pedindo o segundo fator
      // (`requer2fa: true`). Nesse caso não há accessToken para guardar — o
      // fluxo continua na tela de código, que chama [loginDoisFatores].
      if (resp['requer2fa'] == true) {
        return resp;
      }

      // Guarda o accessToken para ser enviado nas próximas requisições.
      await ApiService.setToken(resp['accessToken']);

      return resp;
    }

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

  /// Cadastro público de doador: `POST /usuarios/registro`.
  ///
  /// Em sucesso (201) retorna os dados básicos do usuário criado; em falha
  /// lança [Exception] com a mensagem de `erro` do backend (email duplicado,
  /// senha curta, etc.). Depois do registro o app faz o login normal.
  Future<Map<String, dynamic>> registrar({
    required String nome,
    required String email,
    required String senha,
    String? telefone,
    String? cidade,
    String? estado,
  }) async {
    final url = Uri.parse('$baseUrl/usuarios/registro');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
        if (cidade != null && cidade.isNotEmpty) 'cidade': cidade,
        if (estado != null && estado.isNotEmpty) 'estado': estado,
      }),
    ).timeout(ApiService.timeout);

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

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

  /// Segundo fator do login (2FA): `POST /auth/login-2fa` {email, codigo}.
  ///
  /// Chamado depois que `POST /usuarios/login` respondeu `requer2fa: true`.
  /// Em sucesso (200) a resposta tem o mesmo formato do login normal
  /// (accessToken + dados do usuário) — o token é guardado aqui. Em falha
  /// (ex.: 400 "Código inválido ou expirado.") lança [Exception].
  Future<Map<String, dynamic>> loginDoisFatores({
    required String email,
    required String codigo,
  }) async {
    final response = await ApiService.post(
      '/auth/login-2fa',
      body: jsonEncode({'email': email, 'codigo': codigo}),
    );

    if (response.statusCode == 200) {
      final resp =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      await ApiService.setToken(resp['accessToken']);
      return resp;
    }
    throw Exception(_extrairErro(response));
  }

  /// Passo 1 do "esqueci a senha": `POST /auth/esqueci-senha`.
  ///
  /// Pede ao backend um código de redefinição para o [email]. Em sucesso (200)
  /// retorna `{"mensagem": ...}` e, quando o servidor está em modo
  /// demonstração, também `{"codigoDemo": "123456"}` (em produção o código
  /// iria por e-mail). Em falha lança [Exception] com a mensagem do backend.
  Future<Map<String, dynamic>> esqueciSenha({required String email}) async {
    final response = await ApiService.post(
      '/auth/esqueci-senha',
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    }
    throw Exception(_extrairErro(response));
  }

  /// Passo 2 do "esqueci a senha": `POST /auth/redefinir-senha`.
  ///
  /// Envia o [codigo] recebido + a [novaSenha]. Em sucesso (200) retorna
  /// `{"mensagem": ...}`; em falha (ex.: 400 "Código inválido ou expirado.")
  /// lança [Exception] com a mensagem do backend.
  Future<Map<String, dynamic>> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    final response = await ApiService.post(
      '/auth/redefinir-senha',
      body: jsonEncode({
        'email': email,
        'codigo': codigo,
        'novaSenha': novaSenha,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    }
    throw Exception(_extrairErro(response));
  }

  /// Valida a sessão atual no startup: `GET /auth/me` com o token guardado.
  ///
  /// Retorna `true` se o token ainda é aceito (200), `false` se venceu/foi
  /// invalidado (401) ou se não há token. Usa `http` direto (não os wrappers do
  /// ApiService) DE PROPÓSITO: aqui a checagem é deliberada e o SplashDecider
  /// decide a rota; não queremos disparar o logout global do interceptor no
  /// meio da decisão. Falha de REDE devolve `true` (não desloga por Wi-Fi ruim:
  /// a primeira chamada autenticada real trataria um 401 verdadeiro depois).
  Future<bool> sessaoValida() async {
    if (ApiService.accessToken == null) return false;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: ApiService.authHeaders(),
      ).timeout(ApiService.timeout);
      return response.statusCode != 401;
    } catch (_) {
      // Sem rede/timeout: não é sessão inválida — mantém o usuário logado.
      return true;
    }
  }

  // Extrai a mensagem de `erro` do corpo da resposta (padrão do backend),
  // com fallback para o código HTTP quando o corpo não é o esperado.
  String _extrairErro(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['erro'] != null) {
        return body['erro'].toString();
      }
    } catch (_) {
      // corpo não-JSON: cai no fallback abaixo
    }
    return 'Erro (HTTP ${response.statusCode})';
  }
}