/// Atividade recente da plataforma (feed global da Timeline).
class Atividade {
  final int id;
  final String tipo; // NECESSIDADE | INTERESSE | PRESTACAO | CAMPANHA | DOACAO | AVALIACAO
  final String descricao;
  final int? ongId;
  final String? ongNome;
  final String? dataCriacao; // ISO LocalDateTime (sem timezone)

  const Atividade({
    required this.id,
    required this.tipo,
    required this.descricao,
    this.ongId,
    this.ongNome,
    this.dataCriacao,
  });

  factory Atividade.fromJson(Map<String, dynamic> j) {
    return Atividade(
      id: (j['id'] ?? 0) as int,
      tipo: j['tipo'] ?? '',
      descricao: j['descricao'] ?? '',
      ongId: j['ongId'] as int?,
      ongNome: j['ongNome'],
      dataCriacao: j['dataCriacao'],
    );
  }
}
