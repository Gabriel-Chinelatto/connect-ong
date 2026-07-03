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
  final String? criadoEm;

  const AvaliacaoDoador({
    required this.ongNome,
    required this.nota,
    this.comentario,
    this.criadoEm,
  });

  factory AvaliacaoDoador.fromJson(Map<String, dynamic> j) => AvaliacaoDoador(
        ongNome: j['ongNome'] ?? 'ONG',
        nota: ((j['nota'] ?? 0) as num).toInt(),
        comentario: j['comentario'] as String?,
        criadoEm: j['criadoEm'] as String?,
      );
}

/// Prestação de contas que o doador RECEBEU (das doações dele).
class PrestacaoRecebida {
  final String titulo;
  final String descricao;
  final String ongNome;
  final String necessidadeTitulo;
  final String? criadoEm;

  const PrestacaoRecebida({
    required this.titulo,
    required this.descricao,
    required this.ongNome,
    required this.necessidadeTitulo,
    this.criadoEm,
  });

  factory PrestacaoRecebida.fromJson(Map<String, dynamic> j) =>
      PrestacaoRecebida(
        titulo: j['titulo'] ?? '',
        descricao: j['descricao'] ?? '',
        ongNome: j['ongNome'] ?? 'ONG',
        necessidadeTitulo: j['necessidadeTitulo'] ?? '',
        criadoEm: j['criadoEm'] as String?,
      );
}
