import 'dart:convert';
import 'dart:math';

import '../models/doacao_financeira.dart';
import 'api_service.dart';

/// Servico de doacao financeira (PIX simulado) em DUAS etapas, seguindo o
/// contrato da API:
///
/// 1. POST /doacoes-financeiras/gerar-codigo {"valor": 50.0}
///    → {"codigoPix": "..."} (codigo copia-e-cola exibido ao usuario);
/// 2. POST /doacoes-financeiras {doadorId, ongId, valor, codigoPix, campanhaId?}
///    → registra a doacao e devolve o comprovante (com campanhaTitulo quando a
///    doacao e a contribuicao de uma campanha).
///
/// Tambem lista o historico do proprio doador (GET /doacoes-financeiras?doadorId=).
class DoacaoFinanceiraService {
  /// Historico de doacoes PIX do PROPRIO doador (o backend valida ownership:
  /// so o usuario autenticado pode ver as doacoes do seu doadorId).
  Future<List<DoacaoFinanceira>> listarPorDoador(int doadorId) async {
    final response =
        await ApiService.get('/doacoes-financeiras?doadorId=$doadorId');

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar suas doações PIX');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => DoacaoFinanceira.fromJson(json)).toList();
  }

  /// Etapa 1: gera o codigo PIX copia-e-cola para o valor informado.
  ///
  /// DEGRADACAO GRACIOSA: se o endpoint ainda nao existir no backend (esta
  /// sendo criado em paralelo), gera localmente um codigo no formato
  /// copia-e-cola para a demonstracao continuar funcionando. Erros de REDE
  /// (sem conexao/timeout) continuam estourando para a UI avisar o usuario.
  Future<String> gerarCodigo(double valor) async {
    final response = await ApiService.post(
      '/doacoes-financeiras/gerar-codigo',
      body: jsonEncode({'valor': valor}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final codigo = (body is Map ? body['codigoPix'] : null)?.toString();
        if (codigo != null && codigo.isNotEmpty) return codigo;
      } catch (_) {
        // resposta inesperada → cai no codigo local abaixo
      }
    }
    return _codigoLocal(valor);
  }

  /// Etapa 2: registra a doacao (apos o "pagamento" simulado) e retorna o
  /// comprovante. [campanhaId] vincula a doacao a uma campanha (contribuicao).
  Future<Map<String, dynamic>> doar({
    required int ongId,
    required int doadorId,
    required double valor,
    String? codigoPix,
    int? campanhaId,
  }) async {
    final response = await ApiService.post(
      '/doacoes-financeiras',
      body: jsonEncode({
        'ongId': ongId,
        'doadorId': doadorId,
        'valor': valor,
        if (codigoPix != null) 'codigoPix': codigoPix,
        if (campanhaId != null) 'campanhaId': campanhaId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msgErro;
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        msgErro = (body is Map && body['erro'] != null)
            ? body['erro'].toString()
            : 'Erro (HTTP ${response.statusCode})';
      } catch (_) {
        msgErro = 'Erro (HTTP ${response.statusCode})';
      }
      throw Exception(msgErro);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  // Codigo copia-e-cola de DEMONSTRACAO no formato do PIX (EMV): usado apenas
  // enquanto o endpoint gerar-codigo nao esta disponivel no backend.
  String _codigoLocal(double valor) {
    final rnd = Random();
    final txid = List.generate(25, (_) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      return chars[rnd.nextInt(chars.length)];
    }).join();
    final valorStr = valor.toStringAsFixed(2);
    final campoValor = '54${valorStr.length.toString().padLeft(2, '0')}$valorStr';
    final crc = rnd.nextInt(0x10000).toRadixString(16).toUpperCase().padLeft(4, '0');
    return '00020126580014BR.GOV.BCB.PIX0136$txid'
        '520400005303986$campoValor'
        '5802BR5911CONNECT ONG6009SAO PAULO62070503***6304$crc';
  }
}
