/// Uma necessidade publicada por uma ONG (o que ela precisa receber).
class Necessidade {
  final int id;
  final String titulo;
  final String descricao;
  final String categoria;
  final bool urgente;
  final String status;
  final int? ongId;
  final String? ongNome;
  final bool ongVerificada;

  const Necessidade({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.urgente,
    required this.status,
    this.ongId,
    this.ongNome,
    this.ongVerificada = false,
  });

  factory Necessidade.fromJson(Map<String, dynamic> json) {
    return Necessidade(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      categoria: json['categoria'] ?? '',
      urgente: json['urgente'] ?? false,
      status: json['status'] ?? '',
      ongId: json['ongId'],
      ongNome: json['ongNome'],
      ongVerificada: json['ongVerificada'] ?? false,
    );
  }
}
