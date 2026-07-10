import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Infraestrutura central de rede e sessão do app.
///
/// Responsabilidades:
/// - Define a [baseUrl] da API Spring Boot, usada por todos os serviços
///   (ponto único de configuração do endpoint).
/// - Funciona como armazém do token JWT de acesso: mantém o token em memória
///   e o persiste no SharedPreferences para sobreviver a reinícios do app.
/// - Monta os cabeçalhos de autenticação ([jsonHeaders]/[authHeaders]) com o
///   header `Authorization: Bearer <accessToken>` exigido pelo backend em
///   todos os endpoints protegidos.
///
/// O token é gravado no login (via [setToken]), recarregado no startup (via
/// [carregarToken], chamado em main) e limpo no logout (`setToken(null)`),
/// garantindo que cada usuário acesse apenas os próprios dados.
class ApiService {
  // Endereço base da API (backend Spring Boot).
  // Centralizado aqui para que todas as telas e serviços usem a mesma URL.

  // CHROME / WINDOWS / DESKTOP
  static const String baseUrl = 'http://localhost:8080';

  // ANDROID EMULATOR (descomente ao rodar no emulador Android)
  // static const String baseUrl = 'http://10.0.2.2:8080';

  // ---------------------------------------------------------------------------
  // Armazém central do token JWT.
  //
  // O backend agora exige o header Authorization: Bearer <accessToken> em
  // todos os endpoints protegidos. Guardamos o token aqui (em memória) e
  // também o persistimos no SharedPreferences para sobreviver a reinícios.
  // ---------------------------------------------------------------------------

  // Token de acesso em memória (null quando ninguém está logado).
  static String? _accessToken;

  // Acesso somente-leitura ao token atual.
  static String? get accessToken => _accessToken;

  // Chave usada para persistir o token no SharedPreferences.
  static const String _tokenKey = 'access_token';

  // ---------------------------------------------------------------------------
  // Sessão expirada (401 global).
  //
  // Chaves globais do Navigator e do ScaffoldMessenger: permitem navegar e
  // mostrar SnackBar de FORA da árvore de widgets (a partir desta camada de
  // rede). São ligadas ao MaterialApp em main.dart.
  // ---------------------------------------------------------------------------
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Callback disparado quando uma requisição AUTENTICADA recebe 401 (token
  /// expirado/invalidado). O app registra aqui o logout + retorno ao login
  /// (ver main.dart). Fica como callback para esta camada de rede não depender
  /// da UI/sessão (evita import circular com SessionService).
  static Future<void> Function()? onUnauthorized;

  // Evita disparar vários logouts/navegações quando um lote de requisições
  // recebe 401 ao mesmo tempo (ex.: a home dispara N chamadas de uma vez).
  static bool _tratandoSessaoExpirada = false;

  static Future<void> _sessaoExpirou() async {
    if (_tratandoSessaoExpirada) return;
    _tratandoSessaoExpirada = true;
    try {
      final handler = onUnauthorized;
      if (handler != null) await handler();
    } finally {
      _tratandoSessaoExpirada = false;
    }
  }

  // Define (ou limpa) o token: atualiza a memória e o armazenamento local.
  static Future<void> setToken(String? token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      // Logout / token inválido: remove a chave persistida.
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  // Carrega o token do armazenamento local para a memória (chamado no startup).
  static Future<void> carregarToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
  }

  // Cabeçalhos para requisições com corpo JSON (POST/PUT).
  static Map<String, String> jsonHeaders() => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // Cabeçalhos para requisições sem corpo (GET/DELETE).
  static Map<String, String> authHeaders() => {
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ---------------------------------------------------------------------------
  // Camada de rede com TIMEOUT e tradução de erros.
  //
  // Todos os serviços devem usar estes wrappers em vez de chamar `http`
  // diretamente: assim uma rede que "não responde" (ex.: Wi-Fi caindo) falha em
  // [timeout] segundos em vez de deixar a tela em loading para sempre, e os
  // erros de rede viram mensagens legíveis em vez de SocketException crua.
  // ---------------------------------------------------------------------------

  static const Duration timeout = Duration(seconds: 12);

  static Uri _uri(String caminho) => Uri.parse('$baseUrl$caminho');

  static Future<http.Response> get(String caminho, {bool auth = true}) {
    return _executar(() => http.get(
          _uri(caminho),
          headers: auth ? authHeaders() : null,
        ));
  }

  static Future<http.Response> post(String caminho, {Object? body}) {
    return _executar(() => http.post(
          _uri(caminho),
          headers: jsonHeaders(),
          body: body,
        ));
  }

  static Future<http.Response> put(String caminho, {Object? body}) {
    return _executar(() => http.put(
          _uri(caminho),
          headers: jsonHeaders(),
          body: body,
        ));
  }

  static Future<http.Response> delete(String caminho) {
    return _executar(() => http.delete(
          _uri(caminho),
          headers: authHeaders(),
        ));
  }

  // Aplica o timeout e converte falhas de rede em Exception com mensagem
  // amigável (as demais respostas HTTP seguem para o serviço tratar o status).
  static Future<http.Response> _executar(
      Future<http.Response> Function() acao) async {
    try {
      final resposta = await acao().timeout(timeout);
      // Sessão expirada: um 401 numa requisição que ENVIOU token significa que
      // o token venceu/foi invalidado -> logout global (uma única vez). Um 401
      // SEM token (login, esqueci-senha, endpoints públicos) NÃO desloga: aí o
      // 401 é só "credencial inválida" e o próprio fluxo trata a mensagem.
      if (resposta.statusCode == 401 && _accessToken != null) {
        await _sessaoExpirou();
      }
      return resposta;
    } on TimeoutException {
      throw Exception('O servidor demorou a responder. Tente novamente.');
    } on SocketException {
      throw Exception('Sem conexão. Verifique sua internet.');
    } on http.ClientException {
      throw Exception('Não foi possível conectar ao servidor.');
    }
  }

  /// Converte qualquer erro capturado em uma mensagem amigável para o usuário.
  /// Usar em catches de UI no lugar de expor `e.toString()` cru.
  static String mensagemAmigavel(Object erro) {
    if (erro is TimeoutException) {
      return 'O servidor demorou a responder. Tente novamente.';
    }
    if (erro is SocketException || erro is http.ClientException) {
      return 'Sem conexão. Verifique sua internet.';
    }
    return erro.toString().replaceFirst('Exception: ', '');
  }
}
