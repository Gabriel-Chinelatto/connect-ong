/// Uma prestacao de contas publicada pela ONG num match.
/// Espelha o PrestacaoResponseDTO do backend (GET /prestacoes?interesseId=),
/// que desde o commit f7198d5 tambem traz doador/ONG/necessidade, a lista de
/// `fotos` (base64) e o `valorUtilizado` (pode ser null).
class Prestacao {
  final int id;
  final String titulo;
  final String descricao;
  final String? fotoUrl; // legado (prestacoes antigas por URL)
  final String? dataCriacao;

  final int? doadorId;
  final String? doadorNome;
  final String? ongNome;
  final String? necessidadeTitulo;

  /// Fotos comprovante em base64 (ate 5). Vazio em prestacoes antigas.
  final List<String> fotos;

  /// Valor (R$) utilizado na acao. Null quando a ONG nao informou.
  final double? valorUtilizado;

  const Prestacao({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.fotoUrl,
    this.dataCriacao,
    this.doadorId,
    this.doadorNome,
    this.ongNome,
    this.necessidadeTitulo,
    this.fotos = const [],
    this.valorUtilizado,
  });

  factory Prestacao.fromJson(Map<String, dynamic> json) {
    return Prestacao(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      fotoUrl: json['fotoUrl'],
      dataCriacao: json['dataCriacao'],
      doadorId: (json['doadorId'] as num?)?.toInt(),
      doadorNome: json['doadorNome'] as String?,
      ongNome: json['ongNome'] as String?,
      necessidadeTitulo: json['necessidadeTitulo'] as String?,
      fotos: (json['fotos'] is List)
          ? (json['fotos'] as List)
              .whereType<String>()
              .where((f) => f.isNotEmpty)
              .toList()
          : const <String>[],
      valorUtilizado: (json['valorUtilizado'] as num?)?.toDouble(),
    );
  }
}
