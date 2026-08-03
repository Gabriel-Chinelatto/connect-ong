import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Numeros publicos da plataforma (transparencia / impacto).
class EstatisticasPublicas {
  final int totalOngs;
  final int totalDoadores;
  final int totalNecessidades;
  final int totalMatches;
  final int totalDoacoesFinanceiras;
  final double valorTotalDoado;
  final int totalPrestacoes;

  const EstatisticasPublicas({
    required this.totalOngs,
    required this.totalDoadores,
    required this.totalNecessidades,
    required this.totalMatches,
    required this.totalDoacoesFinanceiras,
    required this.valorTotalDoado,
    required this.totalPrestacoes,
  });

  factory EstatisticasPublicas.fromJson(Map<String, dynamic> j) {
    return EstatisticasPublicas(
      totalOngs: (j['totalOngs'] ?? 0) as int,
      totalDoadores: (j['totalDoadores'] ?? 0) as int,
      totalNecessidades: (j['totalNecessidades'] ?? 0) as int,
      totalMatches: (j['totalMatches'] ?? 0) as int,
      totalDoacoesFinanceiras: (j['totalDoacoesFinanceiras'] ?? 0) as int,
      valorTotalDoado: ((j['valorTotalDoado'] ?? 0) as num).toDouble(),
      totalPrestacoes: (j['totalPrestacoes'] ?? 0) as int,
    );
  }

  static const EstatisticasPublicas zero = EstatisticasPublicas(
    totalOngs: 0,
    totalDoadores: 0,
    totalNecessidades: 0,
    totalMatches: 0,
    totalDoacoesFinanceiras: 0,
    valorTotalDoado: 0,
    totalPrestacoes: 0,
  );
}

/// Servico de transparencia/impacto: carrega os numeros publicos agregados
/// da plataforma (GET /publico/estatisticas) usados nos paineis de impacto.
///
/// CACHE (2026-08): os mesmos numeros aparecem no portal, no login e no Mural,
/// e cada ida ao banco custa ~600ms (backend nos EUA + MySQL no Brasil — ver
/// a regra de performance do projeto). Por isso a resposta fica guardada por
/// [_validade]: navegar entre essas telas passa a ser instantaneo. Chamadas
/// simultaneas compartilham a MESMA requisicao (nao dispara duas).
/// Use `carregar(forcar: true)` no "puxar para atualizar".
class EstatisticaService {
  static final String _url = '${ApiService.baseUrl}/publico/estatisticas';

  static const Duration _validade = Duration(minutes: 2);

  static EstatisticasPublicas? _cache;
  static DateTime? _quando;
  static Future<EstatisticasPublicas>? _emVoo;

  /// Ultimo valor conhecido (para pintar a tela na hora enquanto atualiza).
  static EstatisticasPublicas? get cacheAtual => _cache;

  Future<EstatisticasPublicas> carregar({bool forcar = false}) {
    final valido = _cache != null &&
        _quando != null &&
        DateTime.now().difference(_quando!) < _validade;
    if (!forcar && valido) return Future.value(_cache);
    return _emVoo ??= _buscar().whenComplete(() => _emVoo = null);
  }

  Future<EstatisticasPublicas> _buscar() async {
    final response =
        await http.get(Uri.parse(_url), headers: ApiService.authHeaders())
            .timeout(ApiService.timeout);
    if (response.statusCode == 200) {
      final stats = EstatisticasPublicas.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
      _cache = stats;
      _quando = DateTime.now();
      return stats;
    }
    throw Exception('Erro ao carregar estatísticas');
  }

  /// Limpa o cache (ex.: ao trocar de conta).
  static void invalidar() {
    _cache = null;
    _quando = null;
  }
}
