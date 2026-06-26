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
}
