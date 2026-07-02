/// Uma mensagem de chat dentro de um match.
class Mensagem {
  final int id;
  final int? interesseId;
  final String remetente; // DOADOR ou ONG
  final String conteudo;
  final String? dataEnvio;
  final bool lida; // se a mensagem ja foi vista pelo outro lado

  const Mensagem({
    required this.id,
    required this.remetente,
    required this.conteudo,
    this.interesseId,
    this.dataEnvio,
    this.lida = false,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      id: json['id'],
      interesseId: json['interesseId'],
      remetente: json['remetente'] ?? '',
      conteudo: json['conteudo'] ?? '',
      dataEnvio: json['dataEnvio'],
      lida: (json['lida'] ?? false) as bool,
    );
  }
}
