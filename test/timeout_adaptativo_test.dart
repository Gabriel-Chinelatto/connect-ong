import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/services/api_service.dart';

/// O backend roda no plano gratuito do Render, que DESLIGA o serviço depois de
/// ~15 min sem acesso. A primeira requisição precisa esperar o servidor subir
/// (medido em 2026-08-03: 95s) — com o timeout fixo de 12s a primeira tela
/// falhava sempre com "TimeoutException", inclusive na frente da banca.
///
/// Estes testes travam a regra do timeout adaptativo. Os casos rodam em ordem
/// de propósito: o estado (última resposta) é estático, como no app real.
void main() {
  test('sem nenhuma resposta ainda, espera o tempo LONGO (servidor acordando)',
      () {
    expect(ApiService.apiPodeEstarDormindo, isTrue);
    expect(ApiService.timeout, const Duration(seconds: 100));
  });

  test('depois que a API responde, volta ao tempo CURTO', () {
    ApiService.registrarResposta();

    expect(ApiService.apiPodeEstarDormindo, isFalse);
    expect(ApiService.timeout, const Duration(seconds: 12));
  });

  test('mensagem de demora explica a hibernação em vez do erro cru', () {
    // Com a API já respondendo, a mensagem é a genérica.
    final acordada = ApiService.mensagemAmigavel(
      TimeoutException('Future not completed', const Duration(seconds: 12)),
    );
    expect(acordada, 'O servidor demorou a responder. Tente novamente.');
    // O que o usuário via antes desta correção era exatamente isto:
    expect(acordada, isNot(contains('TimeoutException')));
  });

  // Em 2026-08-04 o Render ficou sem deploy ativo e devolveu 502 em 100% das
  // chamadas; as telas diziam "Não foi possível carregar" sem tentar de novo.
  group('servidor indisponível (5xx de infraestrutura)', () {
    test('502, 503 e 504 contam como servidor fora do ar', () {
      expect(ApiService.servidorIndisponivel(502), isTrue);
      expect(ApiService.servidorIndisponivel(503), isTrue);
      expect(ApiService.servidorIndisponivel(504), isTrue);
    });

    test('erros do próprio pedido NÃO entram na regra (não repetir)', () {
      for (final status in [200, 201, 400, 401, 403, 404, 409, 500]) {
        expect(ApiService.servidorIndisponivel(status), isFalse,
            reason: 'status $status não é indisponibilidade de servidor');
      }
    });
  });
}
