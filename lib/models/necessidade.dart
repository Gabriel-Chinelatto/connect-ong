import 'json_utils.dart';

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
  final String? ongCidade;
  final bool ongVerificada;
  final double ongNotaMedia;
  final int ongTotalAvaliacoes;

  /// Data de publicação (ISO-8601) que o backend está adicionando ao
  /// NecessidadeResponseDTO. Nula em backends antigos — a UI oculta o
  /// "Postado há X" quando ausente (degradação graciosa).
  final String? dataCriacao;

  const Necessidade({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.urgente,
    required this.status,
    this.ongId,
    this.ongNome,
    this.ongCidade,
    this.ongVerificada = false,
    this.ongNotaMedia = 0,
    this.ongTotalAvaliacoes = 0,
    this.dataCriacao,
  });

  factory Necessidade.fromJson(Map<String, dynamic> json) {
    return Necessidade(
      id: asInt(json['id']),
      titulo: asString(json['titulo']),
      descricao: asString(json['descricao']),
      categoria: asString(json['categoria']),
      urgente: asBool(json['urgente']),
      status: asString(json['status']),
      ongId: asIntOrNull(json['ongId']),
      ongNome: asStringOrNull(json['ongNome']),
      ongCidade: asStringOrNull(json['ongCidade']),
      ongVerificada: asBool(json['ongVerificada']),
      ongNotaMedia: asDouble(json['ongNotaMedia']),
      ongTotalAvaliacoes: asInt(json['ongTotalAvaliacoes']),
      dataCriacao: asStringOrNull(json['dataCriacao']),
    );
  }
}
