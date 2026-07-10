import 'dart:convert';

import 'api_service.dart';

/// Resumo de impacto de uma ONG gerado por IA a partir de dados REAIS (nº de
/// necessidades, avaliações, doações...). [modo] = 'ia' | 'regras'.
class ResumoImpacto {
  final String resumo;
  final String modo;

  const ResumoImpacto({required this.resumo, required this.modo});

  bool get modoRegras => modo.toLowerCase() == 'regras';

  factory ResumoImpacto.fromJson(Map<String, dynamic> j) => ResumoImpacto(
        resumo: (j['resumo'] ?? '').toString(),
        modo: (j['modo'] ?? 'regras').toString(),
      );
}

/// Cliente de `POST /ia/resumo-impacto`: o backend junta os números reais da
/// ONG e pede à IA (gratuita, Groq) um parágrafo curto e caloroso. Sem chave, o
/// backend monta o texto por regras. Falha de rede vira mensagem amigável.
class ResumoImpactoService {
  Future<ResumoImpacto> obter(int ongId) async {
    try {
      final resp = await ApiService.post(
        '/ia/resumo-impacto',
        body: jsonEncode({'ongId': ongId}),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Resumo indisponível.');
      }
      final json =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return ResumoImpacto.fromJson(json);
    } catch (e) {
      throw Exception(ApiService.mensagemAmigavel(e));
    }
  }
}
