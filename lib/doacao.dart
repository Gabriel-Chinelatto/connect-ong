/// Modelo de uma doacao trocada com a API (serializavel via JSON).
///
/// Representa um item doado/necessario, com categoria, tipo, quantidade e
/// marcadores de urgencia e novidade.
class Doacao {
  final int? id;

  final String nome;
  final String descricao;
  final int quantidade;
  final String categoria;
  final String tipo;
  final bool urgente;
  final bool novo;

  const Doacao({
    this.id,
    required this.nome,
    required this.descricao,
    required this.quantidade,
    required this.categoria,
    required this.tipo,
    required this.urgente,
    required this.novo,
  });

  factory Doacao.fromJson(
    Map<String, dynamic> json,
  ) {
    return Doacao(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      quantidade: json['quantidade'],
      categoria: json['categoria'],
      tipo: json['tipo'],
      urgente: json['urgente'],
      novo: json['novo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'quantidade': quantidade,
      'categoria': categoria,
      'tipo': tipo,
      'urgente': urgente,
      'novo': novo,
    };
  }

  Doacao copyWith({
    int? id,
    String? nome,
    String? descricao,
    int? quantidade,
    String? categoria,
    String? tipo,
    bool? urgente,
    bool? novo,
  }) {
    return Doacao(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      quantidade: quantidade ?? this.quantidade,
      categoria: categoria ?? this.categoria,
      tipo: tipo ?? this.tipo,
      urgente: urgente ?? this.urgente,
      novo: novo ?? this.novo,
    );
  }
}