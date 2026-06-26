/// Representa uma conquista (gamificacao) do doador.
class Conquista {
  final String chave;
  final String titulo;
  final String descricao;
  final bool conquistada;

  Conquista({
    required this.chave,
    required this.titulo,
    required this.descricao,
    required this.conquistada,
  });

  factory Conquista.fromJson(Map<String, dynamic> json) {
    return Conquista(
      chave: (json['chave'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
      conquistada: json['conquistada'] == true,
    );
  }
}
