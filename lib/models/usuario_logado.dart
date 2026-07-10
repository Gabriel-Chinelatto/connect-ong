import 'json_utils.dart';

/// Representa o usuário autenticado na sessão atual.
///
/// Guarda identidade e papel ([tipo]: 'DOADOR' ou 'ONG'). É serializado para o
/// SharedPreferences pelo [SessionService] e usado para vincular ações às
/// telas (ex.: id do doador nas chamadas à API).
class UsuarioLogado {

  final int id;

  final String nome;

  final String email;

  final String tipo;

  UsuarioLogado({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipo,
  });

  factory UsuarioLogado.fromJson(
    Map<String, dynamic> json,
  ) {

    return UsuarioLogado(

      id: asInt(json['id']),

      nome: asString(json['nome']),

      email: asString(json['email']),

      tipo: asString(json['tipo']),
    );
  }

  Map<String, dynamic> toJson() {

    return {

      'id': id,

      'nome': nome,

      'email': email,

      'tipo': tipo,
    };
  }
}