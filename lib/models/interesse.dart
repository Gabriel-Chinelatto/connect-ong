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

  /// Data em que o interesse foi criado (ISO-8601). Usada para ordenar e para
  /// mostrar "há N dias esperando" nos que aguardam aceite.
  final String? dataCriacao;

  /// Data em que a doação foi concluída (ISO-8601), enviada pelo backend
  /// quando o status é CONCLUIDO. Nula nos demais status ou em backends
  /// antigos (a UI degrada mostrando o card sem a data).
  final String? dataConclusao;

  /// Há quantos dias o doador espera o aceite (só em PENDENTE; null nos demais
  /// status). Calculado no servidor a partir da dataCriacao.
  final int? diasEsperando;

  /// true quando a ONG deste match bloqueou o doador logado: o chat abre com
  /// o envio desabilitado. Ausente no JSON (backend antigo) = false.
  final bool bloqueadoPelaOng;

  const Interesse({
    required this.id,
    required this.status,
    this.necessidadeId,
    this.necessidadeTitulo,
    this.doadorId,
    this.doadorNome,
    this.ongId,
    this.ongNome,
    this.dataCriacao,
    this.dataConclusao,
    this.diasEsperando,
    this.bloqueadoPelaOng = false,
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
      dataCriacao: json['dataCriacao'],
      dataConclusao: json['dataConclusao'],
      diasEsperando: (json['diasEsperando'] as num?)?.toInt(),
      bloqueadoPelaOng: json['bloqueadoPelaOng'] ?? false,
    );
  }
}
