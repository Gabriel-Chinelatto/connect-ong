import 'dart:convert';

import 'api_service.dart';

/// Uma modalidade de frete estimada (ex.: "Correios (estimado)"), com valor,
/// prazo e um detalhe curto. Todos os campos degradam graciosamente.
class ModalidadeFrete {
  final String nome;
  final double valor;
  final int prazoDias;
  final String detalhe;

  const ModalidadeFrete({
    required this.nome,
    required this.valor,
    required this.prazoDias,
    required this.detalhe,
  });

  /// true quando é a entrega combinada localmente (valor zero / sem prazo).
  bool get ehLocal => valor <= 0;

  factory ModalidadeFrete.fromJson(Map<String, dynamic> j) => ModalidadeFrete(
        nome: (j['nome'] ?? '').toString(),
        valor: ((j['valor'] ?? 0) as num).toDouble(),
        prazoDias: (j['prazoDias'] as num?)?.toInt() ?? 0,
        detalhe: (j['detalhe'] ?? '').toString(),
      );
}

/// Estimativa de frete devolvida por `POST /frete/estimar`: origem/destino,
/// distância, peso (informado ou estimado pela IA), categoria, um resumo do
/// item e a lista de modalidades. `aviso` deixa claro que são ESTIMATIVAS, não
/// cotação oficial. `modo` = 'ia' | 'regras'.
class FreteEstimativa {
  final String origem;
  final String destino;
  final int distanciaKm;
  final double pesoKg;
  final bool pesoEstimado;
  final String categoria;
  final String itemResumo;
  final List<ModalidadeFrete> modalidades;
  final String aviso;
  final String modo;

  const FreteEstimativa({
    required this.origem,
    required this.destino,
    required this.distanciaKm,
    required this.pesoKg,
    required this.pesoEstimado,
    required this.categoria,
    required this.itemResumo,
    required this.modalidades,
    required this.aviso,
    required this.modo,
  });

  bool get modoRegras => modo.toLowerCase() == 'regras';

  factory FreteEstimativa.fromJson(Map<String, dynamic> j) {
    final brutas = (j['modalidades'] as List?) ?? const [];
    return FreteEstimativa(
      origem: (j['origem'] ?? '').toString(),
      destino: (j['destino'] ?? '').toString(),
      distanciaKm: (j['distanciaKm'] as num?)?.toInt() ?? 0,
      pesoKg: ((j['pesoKg'] ?? 0) as num).toDouble(),
      pesoEstimado: j['pesoEstimado'] ?? false,
      categoria: (j['categoria'] ?? '').toString(),
      itemResumo: (j['itemResumo'] ?? '').toString(),
      modalidades: brutas
          .whereType<Map>()
          .map((e) => ModalidadeFrete.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .toList(),
      aviso: (j['aviso'] ?? '').toString(),
      modo: (j['modo'] ?? 'regras').toString(),
    );
  }
}

/// Cliente do simulador de frete (`POST /frete/estimar`). O backend calcula a
/// distância entre as cidades (base de municípios do IBGE, offline) e estima o
/// peso pela IA a partir do texto do item, devolvendo modalidades ESTIMADAS —
/// nunca uma cotação oficial. Qualquer falha de rede vira mensagem amigável.
class FreteService {
  Future<FreteEstimativa> estimar({
    required String origemCidade,
    String? origemUf,
    required String destinoCidade,
    String? destinoUf,
    String? item,
    String? categoria,
    int? quantidade,
    double? pesoKg,
  }) async {
    try {
      final resp = await ApiService.post(
        '/frete/estimar',
        body: jsonEncode({
          'origemCidade': origemCidade,
          if (origemUf != null && origemUf.isNotEmpty) 'origemUf': origemUf,
          'destinoCidade': destinoCidade,
          if (destinoUf != null && destinoUf.isNotEmpty) 'destinoUf': destinoUf,
          if (item != null && item.isNotEmpty) 'item': item,
          if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
          if (quantidade != null) 'quantidade': quantidade,
          if (pesoKg != null) 'pesoKg': pesoKg,
        }),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Não foi possível simular o frete agora.');
      }
      final json =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return FreteEstimativa.fromJson(json);
    } catch (e) {
      throw Exception(ApiService.mensagemAmigavel(e));
    }
  }
}
