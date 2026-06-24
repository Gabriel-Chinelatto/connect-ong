/// Avaliacao de uma ONG feita por um doador.
class Avaliacao {
  final int id;
  final String doadorNome;
  final int nota;
  final String? comentario;
  final String? dataCriacao;

  const Avaliacao({
    required this.id,
    required this.doadorNome,
    required this.nota,
    this.comentario,
    this.dataCriacao,
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      id: json['id'],
      doadorNome: json['doadorNome'] ?? 'Doador',
      nota: json['nota'] ?? 0,
      comentario: json['comentario'],
      dataCriacao: json['dataCriacao'],
    );
  }
}
