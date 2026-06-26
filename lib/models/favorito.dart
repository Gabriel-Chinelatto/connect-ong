/// Item favoritado por um doador (ONG ou Campanha).
class Favorito {
  final int id;
  final String tipo; // "ONG" ou "CAMPANHA"
  final int alvoId;
  final String alvoNome;
  final String? dataCriacao;

  const Favorito({
    required this.id,
    required this.tipo,
    required this.alvoId,
    required this.alvoNome,
    this.dataCriacao,
  });

  factory Favorito.fromJson(Map<String, dynamic> j) {
    return Favorito(
      id: (j['id'] ?? 0) as int,
      tipo: (j['tipo'] ?? '') as String,
      alvoId: (j['alvoId'] ?? 0) as int,
      alvoNome: (j['alvoNome'] ?? '') as String,
      dataCriacao: j['dataCriacao'] as String?,
    );
  }
}
