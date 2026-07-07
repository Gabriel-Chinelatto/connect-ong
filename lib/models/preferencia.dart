/// Preferencias/configuracoes do usuario (espelha a entidade do backend).
class Preferencia {
  // Aparencia
  String tema; // CLARO, ESCURO, AUTOMATICO
  String tamanhoFonte; // PEQUENA, MEDIA, GRANDE
  bool altoContraste;
  bool fonteDislexia;
  bool navegacaoSimplificada;
  // Notificacoes
  bool notifMensagens;
  bool notifMatch;
  bool notifCampanhas;
  bool notifNecessidades;
  bool notifNoticias;
  // Privacidade
  bool mostrarTelefone;
  bool mostrarEmail;
  bool perfilPublico;
  bool receberContatos;
  bool receberSugestoes;
  // Seguranca
  /// Verificacao em duas etapas (2FA): a cada login o backend envia um codigo
  /// para confirmar a identidade. Backend antigo sem o campo = false.
  bool doisFatores;

  /// Indica se o JSON de origem TRAZIA o campo `navegacaoSimplificada`.
  /// O backend pode ser antigo e ainda nao ter esse campo — nesse caso o
  /// [ConfigController] usa a copia local (SharedPreferences) como fallback.
  /// Nao e serializado (nao vai no toJson).
  bool navegacaoSimplificadaDoBackend;

  Preferencia({
    this.tema = 'AUTOMATICO',
    this.tamanhoFonte = 'MEDIA',
    this.altoContraste = false,
    this.fonteDislexia = false,
    this.navegacaoSimplificada = false,
    this.notifMensagens = true,
    this.notifMatch = true,
    this.notifCampanhas = true,
    this.notifNecessidades = true,
    this.notifNoticias = true,
    this.mostrarTelefone = true,
    this.mostrarEmail = false,
    this.perfilPublico = true,
    this.receberContatos = true,
    this.receberSugestoes = true,
    this.doisFatores = false,
    this.navegacaoSimplificadaDoBackend = true,
  });

  factory Preferencia.fromJson(Map<String, dynamic> j) {
    bool b(dynamic v, bool padrao) => v is bool ? v : padrao;
    return Preferencia(
      tema: j['tema'] ?? 'AUTOMATICO',
      tamanhoFonte: j['tamanhoFonte'] ?? 'MEDIA',
      altoContraste: b(j['altoContraste'], false),
      fonteDislexia: b(j['fonteDislexia'], false),
      navegacaoSimplificada: b(j['navegacaoSimplificada'], false),
      notifMensagens: b(j['notifMensagens'], true),
      notifMatch: b(j['notifMatch'], true),
      notifCampanhas: b(j['notifCampanhas'], true),
      notifNecessidades: b(j['notifNecessidades'], true),
      notifNoticias: b(j['notifNoticias'], true),
      mostrarTelefone: b(j['mostrarTelefone'], true),
      mostrarEmail: b(j['mostrarEmail'], false),
      perfilPublico: b(j['perfilPublico'], true),
      receberContatos: b(j['receberContatos'], true),
      receberSugestoes: b(j['receberSugestoes'], true),
      doisFatores: b(j['doisFatores'], false),
      navegacaoSimplificadaDoBackend: j.containsKey('navegacaoSimplificada'),
    );
  }

  Map<String, dynamic> toJson() => {
        'tema': tema,
        'tamanhoFonte': tamanhoFonte,
        'altoContraste': altoContraste,
        'fonteDislexia': fonteDislexia,
        'navegacaoSimplificada': navegacaoSimplificada,
        'notifMensagens': notifMensagens,
        'notifMatch': notifMatch,
        'notifCampanhas': notifCampanhas,
        'notifNecessidades': notifNecessidades,
        'notifNoticias': notifNoticias,
        'mostrarTelefone': mostrarTelefone,
        'mostrarEmail': mostrarEmail,
        'perfilPublico': perfilPublico,
        'receberContatos': receberContatos,
        'receberSugestoes': receberSugestoes,
        'doisFatores': doisFatores,
      };

  Preferencia copy() => Preferencia.fromJson(toJson());
}
