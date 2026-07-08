import 'dart:convert';

import 'api_service.dart';

/// Uma sugestao clicavel devolvida pelo assistente: aponta para uma ONG ou
/// uma NECESSIDADE existente no app. A UI a renderiza como um card que abre a
/// tela correspondente (perfil publico da ONG ou detalhe da necessidade).
class SugestaoAssistente {
  /// 'ONG' ou 'NECESSIDADE' (normalizado para maiusculas).
  final String tipo;

  /// Id do recurso apontado (ONG ou necessidade). Pode faltar em respostas
  /// incompletas — a UI degrada (nao navega) quando ausente.
  final int? id;

  final String titulo;
  final String subtitulo;

  const SugestaoAssistente({
    required this.tipo,
    this.id,
    required this.titulo,
    required this.subtitulo,
  });

  bool get ehOng => tipo == 'ONG';
  bool get ehNecessidade => tipo == 'NECESSIDADE';

  factory SugestaoAssistente.fromJson(Map<String, dynamic> json) {
    return SugestaoAssistente(
      tipo: (json['tipo'] ?? '').toString().toUpperCase(),
      id: (json['id'] as num?)?.toInt(),
      titulo: (json['titulo'] ?? '').toString(),
      subtitulo: (json['subtitulo'] ?? '').toString(),
    );
  }

  /// Serializa para o histórico local (persistência das conversas da Dora).
  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        if (id != null) 'id': id,
        'titulo': titulo,
        'subtitulo': subtitulo,
      };
}

/// Resposta do assistente de doacao: o texto a exibir na bolha, uma lista
/// (possivelmente vazia) de [SugestaoAssistente] e o [modo] em que o backend
/// respondeu ('ia' = modelo de linguagem; 'regras' = fallback baseado em
/// regras). Todos os campos degradam graciosamente quando ausentes.
class RespostaAssistente {
  final String resposta;
  final List<SugestaoAssistente> sugestoes;

  /// 'ia' ou 'regras'. Usado apenas para um selo discreto ("Modo basico").
  final String modo;

  /// Titulo sugerido pelo backend para a conversa (opcional). Quando presente,
  /// nomeia a conversa no historico; quando ausente, a UI deriva o titulo da
  /// primeira mensagem do usuario. Degrada para string vazia.
  final String titulo;

  const RespostaAssistente({
    required this.resposta,
    this.sugestoes = const [],
    this.modo = 'ia',
    this.titulo = '',
  });

  /// true quando o backend caiu no fallback de regras (sem IA disponivel).
  bool get modoRegras => modo.toLowerCase() == 'regras';

  factory RespostaAssistente.fromJson(Map<String, dynamic> json) {
    final brutas = (json['sugestoes'] as List?) ?? const [];
    final sugestoes = brutas
        .whereType<Map>()
        .map((e) => SugestaoAssistente.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        // Sem titulo nao vale um card clicavel.
        .where((s) => s.titulo.isNotEmpty)
        .toList();
    return RespostaAssistente(
      resposta: (json['resposta'] ?? '').toString(),
      sugestoes: sugestoes,
      modo: (json['modo'] ?? 'ia').toString(),
      titulo: (json['titulo'] ?? '').toString().trim(),
    );
  }
}

/// Cliente do assistente de doacao por chat (o "botao de IA" do app).
///
/// Fala com `POST /assistente` enviando a mensagem atual, um resumo do
/// historico recente da conversa e (quando conhecida) a cidade do doador, para
/// respostas mais uteis ("ONGs perto de mim"). Qualquer falha de rede vira uma
/// mensagem amigavel via [ApiService.mensagemAmigavel] — a tela mostra uma
/// bolha de erro com "tentar de novo" em vez de quebrar.
class AssistenteService {
  /// Envia [mensagem] ao assistente. [historico] deve ser uma lista de
  /// `{'papel': 'user'|'assistente', 'texto': '...'}` com as ultimas trocas.
  /// [cidade] e opcional (vem do perfil do doador). [imagemBase64] e opcional:
  /// quando o doador anexa uma foto para a Dora "analisar" (ex.: "isto serve
  /// para doar?"). Backends que ainda nao reconhecem o campo simplesmente o
  /// ignoram — a UI degrada mostrando a resposta textual normal.
  Future<RespostaAssistente> perguntar({
    required String mensagem,
    List<Map<String, String>> historico = const [],
    String? cidade,
    String? imagemBase64,
  }) async {
    try {
      final resp = await ApiService.post(
        '/assistente',
        body: jsonEncode({
          'mensagem': mensagem,
          'historico': historico,
          'cidade': cidade,
          if (imagemBase64 != null && imagemBase64.isNotEmpty)
            'imagemBase64': imagemBase64,
        }),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('O assistente esta indisponivel no momento.');
      }
      final json =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return RespostaAssistente.fromJson(json);
    } catch (e) {
      throw Exception(ApiService.mensagemAmigavel(e));
    }
  }
}
