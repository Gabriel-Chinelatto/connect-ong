/// Perfil publico de uma ONG (agrega tudo que o doador ve na pagina da
/// instituicao). Espelha o PerfilPublicoOngDTO do backend.
class PerfilPublicoOng {
  final int id;
  final String nome;
  final String cidade;
  final String descricao;
  final String telefone;
  final String email;
  final String? cnpj;
  final bool verificada;
  final double notaMedia;
  final int totalAvaliacoes;
  final int totalNecessidades;
  final int totalCampanhas;
  final int totalPrestacoes;
  final int transparenciaScore;
  final String nivelTransparencia;
  final List<NecessidadeResumo> necessidades;
  final List<CampanhaResumo> campanhas;
  final List<AvaliacaoResumo> avaliacoes;
  final List<PrestacaoResumo> prestacoes;

  const PerfilPublicoOng({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.descricao,
    required this.telefone,
    required this.email,
    this.cnpj,
    required this.verificada,
    required this.notaMedia,
    required this.totalAvaliacoes,
    required this.totalNecessidades,
    required this.totalCampanhas,
    required this.totalPrestacoes,
    required this.transparenciaScore,
    required this.nivelTransparencia,
    required this.necessidades,
    required this.campanhas,
    required this.avaliacoes,
    required this.prestacoes,
  });

  factory PerfilPublicoOng.fromJson(Map<String, dynamic> j) {
    List<T> lista<T>(String chave, T Function(Map<String, dynamic>) f) {
      final raw = j[chave];
      if (raw is List) {
        return raw.map((e) => f(e as Map<String, dynamic>)).toList();
      }
      return <T>[];
    }

    return PerfilPublicoOng(
      id: (j['id'] ?? 0) as int,
      nome: j['nome'] ?? '',
      cidade: j['cidade'] ?? '',
      descricao: j['descricao'] ?? '',
      telefone: j['telefone'] ?? '',
      email: j['email'] ?? '',
      cnpj: j['cnpj'] as String?,
      verificada: j['verificada'] ?? false,
      notaMedia: ((j['notaMedia'] ?? 0) as num).toDouble(),
      totalAvaliacoes: (j['totalAvaliacoes'] ?? 0) as int,
      totalNecessidades: (j['totalNecessidades'] ?? 0) as int,
      totalCampanhas: (j['totalCampanhas'] ?? 0) as int,
      totalPrestacoes: (j['totalPrestacoes'] ?? 0) as int,
      transparenciaScore: (j['transparenciaScore'] ?? 0) as int,
      nivelTransparencia: j['nivelTransparencia'] ?? 'BRONZE',
      necessidades: lista('necessidades', NecessidadeResumo.fromJson),
      campanhas: lista('campanhas', CampanhaResumo.fromJson),
      avaliacoes: lista('avaliacoes', AvaliacaoResumo.fromJson),
      prestacoes: lista('prestacoes', PrestacaoResumo.fromJson),
    );
  }
}

/// Versao enxuta de uma necessidade exibida na lista do perfil publico da ONG.
class NecessidadeResumo {
  final int id;
  final String titulo;
  final String descricao;
  final String categoria;
  final bool urgente;
  final String status;

  const NecessidadeResumo({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.urgente,
    required this.status,
  });

  factory NecessidadeResumo.fromJson(Map<String, dynamic> j) => NecessidadeResumo(
        id: (j['id'] ?? 0) as int,
        titulo: j['titulo'] ?? '',
        descricao: j['descricao'] ?? '',
        categoria: j['categoria'] ?? '',
        urgente: j['urgente'] ?? false,
        status: j['status'] ?? '',
      );
}

/// Versao enxuta de uma campanha (com progresso) exibida no perfil publico da ONG.
class CampanhaResumo {
  final int id;
  final String titulo;
  final String descricao;
  final double metaValor;
  final double valorArrecadado;
  final int progresso;
  final bool encerrada;

  const CampanhaResumo({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.metaValor,
    required this.valorArrecadado,
    required this.progresso,
    required this.encerrada,
  });

  factory CampanhaResumo.fromJson(Map<String, dynamic> j) => CampanhaResumo(
        id: (j['id'] ?? 0) as int,
        titulo: j['titulo'] ?? '',
        descricao: j['descricao'] ?? '',
        metaValor: ((j['metaValor'] ?? 0) as num).toDouble(),
        valorArrecadado: ((j['valorArrecadado'] ?? 0) as num).toDouble(),
        progresso: (j['progresso'] ?? 0) as int,
        encerrada: j['encerrada'] ?? false,
      );
}

/// Versao enxuta de uma avaliacao (nota + comentario) exibida no perfil publico da ONG.
class AvaliacaoResumo {
  final String doadorNome;
  final int nota;
  final String? comentario;
  final String? dataCriacao;

  const AvaliacaoResumo({
    required this.doadorNome,
    required this.nota,
    this.comentario,
    this.dataCriacao,
  });

  factory AvaliacaoResumo.fromJson(Map<String, dynamic> j) => AvaliacaoResumo(
        doadorNome: j['doadorNome'] ?? 'Anonimo',
        nota: (j['nota'] ?? 0) as int,
        comentario: j['comentario'] as String?,
        dataCriacao: j['dataCriacao'] as String?,
      );
}

/// Versao enxuta de uma prestacao de contas exibida no perfil publico da ONG.
class PrestacaoResumo {
  final String titulo;
  final String descricao;
  final String? fotoUrl;
  final String? dataCriacao;

  const PrestacaoResumo({
    required this.titulo,
    required this.descricao,
    this.fotoUrl,
    this.dataCriacao,
  });

  factory PrestacaoResumo.fromJson(Map<String, dynamic> j) => PrestacaoResumo(
        titulo: j['titulo'] ?? '',
        descricao: j['descricao'] ?? '',
        fotoUrl: j['fotoUrl'] as String?,
        dataCriacao: j['dataCriacao'] as String?,
      );
}
