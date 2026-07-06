import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/preferencia.dart';
import '../services/preferencia_service.dart';

/// Controla as preferencias de aparencia/acessibilidade do app.
/// O MaterialApp escuta este controlador e se reconstroi quando muda.
class ConfigController extends ChangeNotifier {
  ConfigController._();
  static final ConfigController instance = ConfigController._();

  final PreferenciaService _service = PreferenciaService();

  Preferencia _prefs = Preferencia();

  // Ultimo estado PERSISTIDO (carregado do backend ou salvo com sucesso).
  // E o ponto de retorno do preview: a tela de Configuracoes aplica mudancas
  // visuais na hora via [aplicarPreview] e, se o usuario descartar/sair sem
  // salvar, [reverterPreview] volta para esta copia.
  Preferencia _persistido = Preferencia();

  int? _usuarioId;

  Preferencia get prefs => _prefs;

  // ----- Modo Feira (preferencia LOCAL do aparelho) -----
  // Flag persistida no SharedPreferences (nao vai para o backend). Quando
  // ligada, a tela de login exibe as credenciais de demonstracao (util para
  // apresentacoes, ex.: FECITEC). Padrao: ligada.
  static const String _modoFeiraKey = 'modo_feira';
  bool _modoFeira = true;

  bool get modoFeira => _modoFeira;

  /// Carrega a flag do Modo Feira do armazenamento local (chamar no startup).
  Future<void> carregarModoFeira() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _modoFeira = sp.getBool(_modoFeiraKey) ?? true;
      notifyListeners();
    } catch (_) {
      // mantem o padrao (ligado) se falhar ao ler
    }
  }

  /// Liga/desliga o Modo Feira e persiste localmente (aplica na hora).
  Future<void> definirModoFeira(bool valor) async {
    _modoFeira = valor;
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_modoFeiraKey, valor);
    } catch (_) {
      // mantem aplicado em memoria mesmo se o salvar falhar
    }
  }

  // ----- Derivacoes para o tema -----
  ThemeMode get themeMode {
    switch (_prefs.tema) {
      case 'CLARO':
        return ThemeMode.light;
      case 'ESCURO':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  double get textScale {
    switch (_prefs.tamanhoFonte) {
      case 'PEQUENA':
        return 0.9;
      case 'GRANDE':
        return 1.2;
      default:
        return 1.0;
    }
  }

  bool get fonteDislexia => _prefs.fonteDislexia;
  bool get altoContraste => _prefs.altoContraste;
  bool get navegacaoSimplificada => _prefs.navegacaoSimplificada;

  // ----- Navegacao simplificada: fallback LOCAL -----
  // O campo `navegacaoSimplificada` vai junto das preferencias no backend
  // (PUT /usuarios/{id}/preferencias). Como o backend pode ser antigo e ainda
  // nao ter esse campo, gravamos TAMBEM uma copia no SharedPreferences
  // (chave 'navegacao_simplificada'): ao carregar, se o JSON do backend nao
  // trouxer o campo, vale a copia local.
  static const String _navSimplificadaKey = 'navegacao_simplificada';

  Future<bool?> _lerNavSimplificadaLocal() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getBool(_navSimplificadaKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _gravarNavSimplificadaLocal(bool valor) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_navSimplificadaKey, valor);
    } catch (_) {
      // preferencia local e um fallback; falha aqui nao pode quebrar o fluxo
    }
  }

  // Carrega as preferencias do usuario apos o login.
  Future<void> carregar(int usuarioId) async {
    _usuarioId = usuarioId;
    try {
      final carregada = await _service.obter(usuarioId);
      // Backend antigo sem o campo navegacaoSimplificada: usa a copia local.
      if (!carregada.navegacaoSimplificadaDoBackend) {
        carregada.navegacaoSimplificada = await _lerNavSimplificadaLocal() ??
            carregada.navegacaoSimplificada;
      }
      _prefs = carregada;
      _persistido = carregada.copy();
      notifyListeners();
    } catch (_) {
      // mantem os padroes se falhar, mas ainda tenta a flag local
      final local = await _lerNavSimplificadaLocal();
      if (local != null) {
        _prefs.navegacaoSimplificada = local;
        _persistido = _prefs.copy();
        notifyListeners();
      }
    }
  }

  // ----- Preview (usado pela tela de Configuracoes) -----

  /// Aplica [p] visualmente na hora (tema/fonte/contraste/etc.) SEM persistir.
  /// O estado final so vira definitivo em [atualizar]; para desfazer, chame
  /// [reverterPreview].
  void aplicarPreview(Preferencia p) {
    _prefs = p.copy();
    notifyListeners();
  }

  /// Desfaz qualquer preview pendente, voltando ao ultimo estado persistido
  /// (o que veio do backend no carregar ou o do ultimo salvar).
  void reverterPreview() {
    _prefs = _persistido.copy();
    notifyListeners();
  }

  // Aplica e persiste novas preferencias (atualiza a tela na hora).
  Future<void> atualizar(Preferencia novo) async {
    _prefs = novo.copy();
    _persistido = novo.copy();
    notifyListeners();
    // Copia local da navegacao simplificada (fallback p/ backend antigo).
    await _gravarNavSimplificadaLocal(novo.navegacaoSimplificada);
    if (_usuarioId != null) {
      try {
        await _service.salvar(_usuarioId!, novo);
      } catch (_) {
        // mantem aplicado localmente mesmo se o salvar falhar
      }
    }
  }

  // Volta ao estado padrao (no logout).
  void limpar() {
    _prefs = Preferencia();
    _persistido = Preferencia();
    _usuarioId = null;
    notifyListeners();
  }
}
