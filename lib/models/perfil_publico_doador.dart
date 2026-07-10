/// Perfil PÚBLICO de um doador — espelha o PerfilPublicoDoadorDTO do backend
/// (GET /usuarios/{id}/perfil-publico, endpoint público).
///
/// Campos opcionais (membroDesde, fotoBase64…) podem vir null em contas
/// antigas: a UI degrada graciosamente omitindo as seções correspondentes.
class PerfilPublicoDoador {
  final int id;
  final String nome;
  final String cidade;
  final String estado;
  final String fotoBase64;
  final String? membroDesde; // ISO; null em contas antigas

  /// Contato PÚBLICO: só vem preenchido quando o doador ligou os toggles de
  /// privacidade ("Exibir e-mail" / "Exibir telefone"). Null = oculto (ou
  /// backend antigo sem o campo): a seção "Contato" some.
  final String? email;
  final String? telefone;

  final double notaMediaDoador;
  final int totalAvaliacoesDoador;
  final int matchesConcluidos;
  final int totalDoacoesPix;
  final List<AvaliacaoDoador> avaliacoes;
  final List<PrestacaoRecebida> prestacoesRecebidas;

  const PerfilPublicoDoador({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.estado,
    required this.fotoBase64,
    this.membroDesde,
    this.email,
    this.telefone,
    required this.notaMediaDoador,
    required this.totalAvaliacoesDoador,
    required this.matchesConcluidos,
    required this.totalDoacoesPix,
    required this.avaliacoes,
    required this.prestacoesRecebidas,
  });

  /// Badge "Doador 5 estrelas": média >= 4.8 com pelo menos 1 avaliação.
  bool get doadorCincoEstrelas =>
      notaMediaDoador >= 4.8 && totalAvaliacoesDoador >= 1;

  /// Há algum contato público para exibir?
  bool get temContato =>
      (email?.isNotEmpty ?? false) || (telefone?.isNotEmpty ?? false);

  // Normaliza um campo textual opcional: string não-vazia ou null (trata ""
  // e valores não-String como ausentes).
  static String? _limpo(dynamic v) {
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    return null;
  }

  factory PerfilPublicoDoador.fromJson(Map<String, dynamic> j) {
    final stats = (j['stats'] is Map<String, dynamic>)
        ? j['stats'] as Map<String, dynamic>
        : const <String, dynamic>{};

    List<T> lista<T>(String chave, T Function(Map<String, dynamic>) f) {
      final raw = j[chave];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(f)
            .toList();
      }
      return <T>[];
    }

    return PerfilPublicoDoador(
      id: (j['id'] ?? 0) as int,
      nome: j['nome'] ?? '',
      cidade: j['cidade'] ?? '',
      estado: j['estado'] ?? '',
      fotoBase64: j['fotoBase64'] ?? '',
      membroDesde: j['membroDesde'] as String?,
      email: _limpo(j['email']),
      telefone: _limpo(j['telefone']),
      notaMediaDoador: ((j['notaMediaDoador'] ?? 0) as num).toDouble(),
      totalAvaliacoesDoador: ((j['totalAvaliacoesDoador'] ?? 0) as num).toInt(),
      matchesConcluidos: ((stats['matchesConcluidos'] ?? 0) as num).toInt(),
      totalDoacoesPix: ((stats['totalDoacoesPix'] ?? 0) as num).toInt(),
      avaliacoes: lista('avaliacoes', AvaliacaoDoador.fromJson),
      prestacoesRecebidas:
          lista('prestacoesRecebidas', PrestacaoRecebida.fromJson),
    );
  }
}

/// "O que as ONGs dizem": avaliação que uma ONG fez deste doador.
class AvaliacaoDoador {
  final String ongNome;
  final int nota;
  final String? comentario;
  final List<String> fotos; // base64 da doação recebida (pode ser vazio)
  final String? criadoEm;

  const AvaliacaoDoador({
    required this.ongNome,
    required this.nota,
    this.comentario,
    this.fotos = const [],
    this.criadoEm,
  });

  factory AvaliacaoDoador.fromJson(Map<String, dynamic> j) => AvaliacaoDoador(
        ongNome: j['ongNome'] ?? 'ONG',
        nota: ((j['nota'] ?? 0) as num).toInt(),
        comentario: j['comentario'] as String?,
        fotos: (j['fotos'] as List?)?.whereType<String>().toList() ?? const [],
        criadoEm: j['criadoEm'] as String?,
      );
}

/// Prestação de contas que o doador RECEBEU (das doações dele).
///
/// [ongId] identifica a ONG que prestou contas (contraparte) — o backend o
/// adiciona para tornar o nome da ONG clicável (abre o perfil dela). Ausente
/// (null) em backend antigo: a UI degrada mostrando o nome sem link.
class PrestacaoRecebida {
  final String titulo;
  final String descricao;
  final int? ongId;
  final String ongNome;
  final String necessidadeTitulo;
  final String? criadoEm;

  const PrestacaoRecebida({
    required this.titulo,
    required this.descricao,
    this.ongId,
    required this.ongNome,
    required this.necessidadeTitulo,
    this.criadoEm,
  });

  factory PrestacaoRecebida.fromJson(Map<String, dynamic> j) =>
      PrestacaoRecebida(
        titulo: j['titulo'] ?? '',
        descricao: j['descricao'] ?? '',
        ongId: (j['ongId'] as num?)?.toInt(),
        ongNome: j['ongNome'] ?? 'ONG',
        necessidadeTitulo: j['necessidadeTitulo'] ?? '',
        criadoEm: j['criadoEm'] as String?,
      );
}
