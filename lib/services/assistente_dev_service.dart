import 'dart:convert';

import 'api_service.dart';

/// Resposta do assistente "Sobre o Desenvolvimento" (POST /assistente-dev):
/// o texto a exibir na bolha e o [modo] em que o backend respondeu
/// ('ia' = modelo de linguagem; 'regras' = fallback local). Degrada
/// graciosamente quando os campos vem ausentes.
class RespostaDev {
  final String resposta;

  /// 'ia' ou 'regras'. Usado apenas para um selo discreto ("Modo basico").
  final String modo;

  const RespostaDev({required this.resposta, this.modo = 'ia'});

  bool get modoRegras => modo.toLowerCase() == 'regras';

  factory RespostaDev.fromJson(Map<String, dynamic> json) => RespostaDev(
        resposta: (json['resposta'] ?? '').toString(),
        modo: (json['modo'] ?? 'ia').toString(),
      );
}

/// Cliente do chat "Sobre o Desenvolvimento": explica COMO o Connect ONG foi
/// construido (stack, metodos, decisoes, historico de versoes).
///
/// Fala com `POST /assistente-dev`, que responde com IA ancorada num documento
/// curado do projeto (grounding) e cai num fallback por regras quando a IA esta
/// indisponivel. Rota PUBLICA — funciona com ou sem login. Qualquer falha de
/// rede vira uma mensagem amigavel via [ApiService.mensagemAmigavel].
class AssistenteDevService {
  /// Envia [mensagem] ao assistente de desenvolvimento. [historico] e uma lista
  /// de `{'papel': 'user'|'assistente', 'texto': '...'}` com as ultimas trocas.
  Future<RespostaDev> perguntar({
    required String mensagem,
    List<Map<String, String>> historico = const [],
  }) async {
    try {
      final resp = await ApiService.post(
        '/assistente-dev',
        body: jsonEncode({
          'mensagem': mensagem,
          'historico': historico,
        }),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('O assistente esta indisponivel no momento.');
      }
      final json =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return RespostaDev.fromJson(json);
    } catch (e) {
      throw Exception(ApiService.mensagemAmigavel(e));
    }
  }
}
