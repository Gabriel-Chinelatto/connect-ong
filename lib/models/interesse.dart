/// O interesse de um doador em uma necessidade (um "match" quando ACEITO).
class Interesse {
  final int id;
  final String status; // PENDENTE, ACEITO, RECUSADO, CONCLUIDO
  final int? necessidadeId;
  final String? necessidadeTitulo;
  final int? doadorId;
  final String? doadorNome;
  final int? ongId;
  final String? ongNome;

  /// Data em que a doação foi concluída (ISO-8601), enviada pelo backend
  /// quando o status é CONCLUIDO. Nula nos demais status ou em backends
  /// antigos (a UI degrada mostrando o card sem a data).
  final String? dataConclusao;

  const Interesse({
    required this.id,
    required this.status,
    this.necessidadeId,
    this.necessidadeTitulo,
    this.doadorId,
    this.doadorNome,
    this.ongId,
    this.ongNome,
    this.dataConclusao,
  });

  factory Interesse.fromJson(Map<String, dynamic> json) {
    return Interesse(
      id: json['id'],
      status: json['status'] ?? '',
      necessidadeId: json['necessidadeId'],
      necessidadeTitulo: json['necessidadeTitulo'],
      doadorId: json['doadorId'],
      doadorNome: json['doadorNome'],
      ongId: json['ongId'],
      ongNome: json['ongNome'],
      dataConclusao: json['dataConclusao'],
    );
  }
}
