import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'assistente_service.dart';

/// Uma mensagem persistida de uma conversa com a Dora.
///
/// Guarda o papel ('user' ou 'assistente'), o texto e — quando existirem — a
/// foto que o doador anexou (em base64, para reaparecer na bolha ao reabrir) e
/// as sugestoes clicaveis que a Dora devolveu. Bolhas de erro de rede sao
/// transitorias e NAO sao persistidas.
class MensagemDora {
  /// 'user' ou 'assistente'.
  final String papel;
  final String texto;

  /// Foto anexada pelo doador (base64), so em mensagens 'user'. Persistida para
  /// que a imagem reapareca ao reabrir a conversa (as fotos ja vem reduzidas a
  /// ~1024px/qualidade 70, entao sao leves o bastante para o storage local).
  final String? imagemBase64;

  /// Cards de sugestao (ONG/NECESSIDADE), so em mensagens 'assistente'.
  final List<SugestaoAssistente> sugestoes;

  /// true quando a Dora respondeu no modo de regras (selo "Modo basico").
  final bool modoRegras;

  const MensagemDora({
    required this.papel,
    required this.texto,
    this.imagemBase64,
    this.sugestoes = const [],
    this.modoRegras = false,
  });

  bool get ehUsuario => papel == 'user';

  Map<String, dynamic> toJson() => {
        'papel': papel,
        'texto': texto,
        if (imagemBase64 != null && imagemBase64!.isNotEmpty)
          'imagemBase64': imagemBase64,
        if (sugestoes.isNotEmpty)
          'sugestoes': sugestoes.map((s) => s.toJson()).toList(),
        if (modoRegras) 'modoRegras': true,
      };

  factory MensagemDora.fromJson(Map<String, dynamic> json) {
    final brutas = (json['sugestoes'] as List?) ?? const [];
    final sugestoes = brutas
        .whereType<Map>()
        .map((e) => SugestaoAssistente.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .where((s) => s.titulo.isNotEmpty)
        .toList();
    final papel = (json['papel'] ?? 'assistente').toString();
    return MensagemDora(
      papel: papel == 'user' ? 'user' : 'assistente',
      texto: (json['texto'] ?? '').toString(),
      imagemBase64: (json['imagemBase64'] as String?),
      sugestoes: sugestoes,
      modoRegras: json['modoRegras'] == true,
    );
  }
}

/// Uma conversa completa com a Dora (estilo ChatGPT): tem um titulo, uma lista
/// de mensagens, um marcador de fixada e datas de criacao/atualizacao.
class ConversaDora {
  final String id;
  String titulo;
  final List<MensagemDora> mensagens;
  bool fixado;
  final DateTime criadoEm;
  DateTime atualizadoEm;

  ConversaDora({
    required this.id,
    this.titulo = '',
    List<MensagemDora>? mensagens,
    this.fixado = false,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  })  : mensagens = mensagens ?? [],
        criadoEm = criadoEm ?? DateTime.now(),
        atualizadoEm = atualizadoEm ?? DateTime.now();

  /// Cria uma conversa nova e vazia, com id unico baseado no relogio.
  factory ConversaDora.nova() {
    final agora = DateTime.now();
    return ConversaDora(
      id: agora.microsecondsSinceEpoch.toString(),
      criadoEm: agora,
      atualizadoEm: agora,
    );
  }

  /// true enquanto o doador ainda nao mandou nenhuma mensagem (so o "oi" da
  /// Dora). Usado para nao persistir conversas vazias.
  bool get temMensagemDoUsuario => mensagens.any((m) => m.ehUsuario);

  /// Titulo a exibir na lista: o [titulo] definido, ou um fallback amigavel.
  String get tituloExibicao =>
      titulo.trim().isNotEmpty ? titulo.trim() : 'Nova conversa';

  /// Um preview curto da ultima mensagem (para o subtitulo do item da lista).
  String get preview {
    if (mensagens.isEmpty) return 'Toque para conversar com a Dora';
    final ultima = mensagens.last;
    final texto = ultima.texto.trim();
    if (texto.isEmpty) {
      return ultima.imagemBase64 != null ? '📷 Foto' : '';
    }
    return texto.replaceAll('\n', ' ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'fixado': fixado,
        'criadoEm': criadoEm.toIso8601String(),
        'atualizadoEm': atualizadoEm.toIso8601String(),
        'mensagens': mensagens.map((m) => m.toJson()).toList(),
      };

  factory ConversaDora.fromJson(Map<String, dynamic> json) {
    final brutas = (json['mensagens'] as List?) ?? const [];
    final mensagens = brutas
        .whereType<Map>()
        .map((e) => MensagemDora.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .toList();
    return ConversaDora(
      id: (json['id'] ?? DateTime.now().microsecondsSinceEpoch).toString(),
      titulo: (json['titulo'] ?? '').toString(),
      fixado: json['fixado'] == true,
      criadoEm: DateTime.tryParse((json['criadoEm'] ?? '').toString()) ??
          DateTime.now(),
      atualizadoEm: DateTime.tryParse((json['atualizadoEm'] ?? '').toString()) ??
          DateTime.now(),
      mensagens: mensagens,
    );
  }
}

/// Persistencia LOCAL das conversas da Dora (estilo ChatGPT).
///
/// Guarda no SharedPreferences uma LISTA de [ConversaDora] em JSON (chave
/// [_chaveConversas]) e o id da ultima conversa aberta (chave [_chaveUltima]),
/// para restaurar a mesma conversa quando o doador reabre a tela. Tudo e
/// best-effort: qualquer JSON corrompido degrada para "sem conversas" em vez de
/// quebrar o app.
///
/// IMAGEM: a foto anexada e persistida em base64 dentro da mensagem, para
/// reaparecer na bolha ao reabrir. As fotos ja chegam reduzidas (~1024px,
/// qualidade 70) pelo ImagePicker, entao cabem bem no storage local.
class ConversasDoraService {
  static const String _chaveConversas = 'dora_conversas_v1';
  static const String _chaveUltima = 'dora_ultima_conversa_v1';

  /// Lista todas as conversas ja ordenadas (fixadas primeiro, depois por
  /// atualizadoEm desc).
  Future<List<ConversaDora>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chaveConversas);
    if (bruto == null || bruto.isEmpty) return [];
    try {
      final lista = (jsonDecode(bruto) as List)
          .whereType<Map>()
          .map((e) => ConversaDora.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .toList();
      _ordenar(lista);
      return lista;
    } catch (_) {
      // JSON corrompido: comeca do zero em vez de travar.
      return [];
    }
  }

  /// Ordena in-place: fixadas primeiro, depois por atualizadoEm desc.
  void _ordenar(List<ConversaDora> lista) {
    lista.sort((a, b) {
      if (a.fixado != b.fixado) return a.fixado ? -1 : 1;
      return b.atualizadoEm.compareTo(a.atualizadoEm);
    });
  }

  Future<void> _escrever(List<ConversaDora> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chaveConversas,
      jsonEncode(lista.map((c) => c.toJson()).toList()),
    );
  }

  /// Insere ou atualiza [conversa] (upsert por id) e persiste. Nao grava
  /// conversas ainda sem nenhuma mensagem do usuario (evita "conversas vazias"
  /// no historico).
  Future<void> salvar(ConversaDora conversa) async {
    if (!conversa.temMensagemDoUsuario) return;
    final lista = await listar();
    final idx = lista.indexWhere((c) => c.id == conversa.id);
    if (idx >= 0) {
      lista[idx] = conversa;
    } else {
      lista.add(conversa);
    }
    await _escrever(lista);
  }

  Future<void> excluir(String id) async {
    final lista = await listar();
    lista.removeWhere((c) => c.id == id);
    await _escrever(lista);
    // Se era a ultima aberta, esquece a referencia.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_chaveUltima) == id) {
      await prefs.remove(_chaveUltima);
    }
  }

  Future<void> renomear(String id, String titulo) async {
    final lista = await listar();
    final idx = lista.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    lista[idx].titulo = titulo.trim();
    lista[idx].atualizadoEm = DateTime.now();
    await _escrever(lista);
  }

  Future<void> alternarFixado(String id) async {
    final lista = await listar();
    final idx = lista.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    lista[idx].fixado = !lista[idx].fixado;
    await _escrever(lista);
  }

  /// Marca [id] como a ultima conversa aberta (para restaurar ao reabrir).
  Future<void> definirUltima(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveUltima, id);
  }

  /// Recupera a ultima conversa aberta, ou null se nao houver / sumiu.
  Future<ConversaDora?> obterUltima() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_chaveUltima);
    if (id == null) return null;
    final lista = await listar();
    for (final c in lista) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Deriva um titulo a partir da primeira mensagem do usuario: limpa quebras,
  /// capitaliza e limita a ~40 chars. Vazio -> 'Nova conversa'.
  static String tituloDerivado(String mensagem) {
    var t = mensagem.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return 'Nova conversa';
    if (t.length > 40) {
      t = '${t.substring(0, 40).trimRight()}…';
    }
    return t[0].toUpperCase() + t.substring(1);
  }

  /// Garante um titulo unico entre [existentes] (dedupe estilo " (2)", " (3)").
  /// [ignorarId] exclui a propria conversa da checagem.
  static String tituloUnico(
    String base,
    List<ConversaDora> existentes, {
    String? ignorarId,
  }) {
    final usados = existentes
        .where((c) => c.id != ignorarId)
        .map((c) => c.titulo.trim().toLowerCase())
        .toSet();
    if (!usados.contains(base.toLowerCase())) return base;
    var n = 2;
    while (usados.contains('$base ($n)'.toLowerCase())) {
      n++;
    }
    return '$base ($n)';
  }
}
