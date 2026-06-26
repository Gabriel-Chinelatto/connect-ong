import '../models/usuario_logado.dart';

import 'auth_service.dart';
import 'session_service.dart';

/// Orquestra o fluxo de login de ponta a ponta.
///
/// Autentica via [AuthService], valida que o tipo do usuário corresponde ao
/// perfil selecionado na tela (0 = DOADOR, 1 = ONG) — recusando logins de
/// perfil incompatível — e, em sucesso, salva a sessão via [SessionService].
class LoginService {

  final AuthService _authService =
      AuthService();

  final SessionService _sessionService =
      SessionService();

  Future<UsuarioLogado> fazerLogin({

    required String email,

    required String senha,

    required int tipoSelecionado,

  }) async {

    final response =
        await _authService.login(

      email: email,

      senha: senha,
    );

    final usuario =
        UsuarioLogado.fromJson(
      response,
    );

    if (tipoSelecionado == 0 &&
        usuario.tipo != 'DOADOR') {

      throw Exception(
        'Usuário não cadastrado como Doador.',
      );
    }

    if (tipoSelecionado == 1 &&
        usuario.tipo != 'ONG') {

      throw Exception(
        'Usuário não cadastrado como ONG.',
      );
    }

    await _sessionService.salvarUsuario(
      usuario,
    );

    return usuario;
  }
}