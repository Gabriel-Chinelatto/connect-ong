/// Uma prestacao de contas publicada pela ONG num match.
class Prestacao {
  final int id;
  final String titulo;
  final String descricao;
  final String? fotoUrl;
  final String? dataCriacao;

  const Prestacao({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.fotoUrl,
    this.dataCriacao,
  });

  factory Prestacao.fromJson(Map<String, dynamic> json) {
    return Prestacao(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      fotoUrl: json['fotoUrl'],
      dataCriacao: json['dataCriacao'],
    );
  }
}
