import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario_logado.dart';

class SessionService {

  static const String usuarioKey =
      'usuario_logado';

  Future<void> salvarUsuario(
    UsuarioLogado usuario,
  ) async {

    final prefs =
        await SharedPreferences.getInstance();

    final usuarioJson =
        jsonEncode(usuario.toJson());

    await prefs.setString(
      usuarioKey,
      usuarioJson,
    );
  }

  Future<UsuarioLogado?> obterUsuario() async {

    final prefs =
        await SharedPreferences.getInstance();

    final usuarioString =
        prefs.getString(usuarioKey);

    if (usuarioString == null) {

      return null;
    }

    final usuarioJson =
        jsonDecode(usuarioString);

    return UsuarioLogado.fromJson(
      usuarioJson,
    );
  }

  Future<void> logout() async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(usuarioKey);
  }
}