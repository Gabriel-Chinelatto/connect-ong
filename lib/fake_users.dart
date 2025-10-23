class Usuario {
  final String email;
  final String senha;
  final String tipo; // 'doador' ou 'receptor'

  Usuario({required this.email, required this.senha, required this.tipo});
}


final List<Usuario> usuariosCadastrados = [
  Usuario(email: 'lucas@connectong.com', senha: '123', tipo: 'receptor'),
  Usuario(email: 'gabriel@connectong.com', senha: '123', tipo: 'doador'),
  Usuario(email: 'arthur@connectong.com', senha: '123', tipo: 'receptor'),
  Usuario(email: 'luan@connectong.com', senha: '123', tipo: 'doador'),
  Usuario(email: 'abner@connectong.com', senha: '123', tipo: 'receptor'),
];