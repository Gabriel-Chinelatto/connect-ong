class Ong {
  final int? id; // ID agora é int, como geralmente é em APIs Spring Boot com Long
  final String nome;
  final String email;
  final String telefone;
  final String cidade;
  final String descricao;

  Ong({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.cidade,
    required this.descricao,
  });

  // Converte Ong para Map, ignorando ID nulo
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cidade': cidade,
      'descricao': descricao,
    };
  }

  // Construtor factory para criar Ong a partir do JSON da API
  factory Ong.fromJson(Map<String, dynamic> json) {
    return Ong(
      id: json['id'] as int?,
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      telefone: json['telefone'] ?? '',
      cidade: json['cidade'] ?? '',
      descricao: json['descricao'] ?? '',
    );
  }
}