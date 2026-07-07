import '../models/usuario_logado.dart';

import 'auth_service.dart';
import 'session_service.dart';

/// Resultado do login: ou entrou de vez ([usuario] preenchido), ou o backend
/// pediu o segundo fator ([requer2fa] = true, com o e-mail e — em modo
/// demonstração — o [codigoDemo] para mostrar na tela de código).
class LoginResultado {
  final UsuarioLogado? usuario;
  final bool requer2fa;
  final String? email;
  final String? codigoDemo;

  const LoginResultado.ok(UsuarioLogado this.usuario)
      : requer2fa = false,
        email = null,
        codigoDemo = null;

  const LoginResultado.precisa2fa({required String this.email, this.codigoDemo})
      : usuario = null,
        requer2fa = true;
}

/// Orquestra o fluxo de login de ponta a ponta.
///
/// Autentica via [AuthService], valida que o tipo do usuário corresponde ao
/// perfil selecionado na tela (0 = DOADOR, 1 = ONG) — recusando logins de
/// perfil incompatível — e, em sucesso, salva a sessão via [SessionService].
///
/// Quando o backend exige verificação em duas etapas, o login normal volta com
/// [LoginResultado.requer2fa]; a tela então coleta o código e chama
/// [finalizarDoisFatores] para concluir.
class LoginService {

  final AuthService _authService =
      AuthService();

  final SessionService _sessionService =
      SessionService();

  Future<LoginResultado> fazerLogin({

    required String email,

    required String senha,

    required int tipoSelecionado,

  }) async {

    final response =
        await _authService.login(

      email: email,

      senha: senha,
    );

    // Backend pediu o segundo fator: não há usuário/token ainda.
    if (response['requer2fa'] == true) {
      return LoginResultado.precisa2fa(
        email: (response['email'] ?? email).toString(),
        codigoDemo: response['codigoDemo']?.toString(),
      );
    }

    final usuario = await _finalizar(response, tipoSelecionado);
    return LoginResultado.ok(usuario);
  }

  /// Conclui o login após o segundo fator (2FA): valida o código no backend,
  /// recebe o token + dados do usuário e salva a sessão.
  Future<UsuarioLogado> finalizarDoisFatores({
    required String email,
    required String codigo,
    required int tipoSelecionado,
  }) async {
    final response = await _authService.loginDoisFatores(
      email: email,
      codigo: codigo,
    );
    return _finalizar(response, tipoSelecionado);
  }

  // Valida o tipo do usuário e persiste a sessão. Compartilhado pelo login
  // normal e pelo login com 2FA.
  Future<UsuarioLogado> _finalizar(
    Map<String, dynamic> response,
    int tipoSelecionado,
  ) async {
    final usuario = UsuarioLogado.fromJson(response);

    if (tipoSelecionado == 0 && usuario.tipo != 'DOADOR') {
      throw Exception('Usuário não cadastrado como Doador.');
    }

    if (tipoSelecionado == 1 && usuario.tipo != 'ONG') {
      throw Exception('Usuário não cadastrado como ONG.');
    }

    await _sessionService.salvarUsuario(usuario);
    return usuario;
  }
}
