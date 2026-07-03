import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/doacao_financeira.dart';
import '../models/interesse.dart';

/// Gera relatorios em PDF a partir dos dados ja carregados no app.
///
/// Nao depende de novos endpoints: recebe as DOACOES REAIS que a tela
/// "Minhas Doacoes" ja possui em memoria — doacoes via PIX (com valor, ONG e
/// data) e itens doados (matches ACEITOS com as ONGs).
class RelatorioPdfService {
  RelatorioPdfService._();

  static const PdfColor _verdeMarca = PdfColor.fromInt(0xFF0A8449);
  static const PdfColor _verdeClaro = PdfColor.fromInt(0xFFEAF6EE);

  /// Monta o PDF do historico de doacoes reais do doador e devolve os bytes
  /// prontos para compartilhar/imprimir via package `printing`.
  static Future<Uint8List> historicoDoacoes({
    required List<DoacaoFinanceira> doacoesPix,
    required List<Interesse> itensDoados,
    String? nomeDoador,
  }) async {
    final doc = pw.Document();

    final dataGeracao = _formatarDataHora(DateTime.now());

    final totalPix =
        doacoesPix.fold<double>(0, (soma, d) => soma + d.valor);

    final linhasPix = doacoesPix.map((d) {
      return <String>[d.dataFormatada, d.ongNome, d.valorFormatado];
    }).toList();

    final linhasItens = itensDoados.map((m) {
      return <String>[
        m.necessidadeTitulo ?? 'Item doado',
        m.ongNome ?? 'ONG',
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.SizedBox();
          }
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              'Historico de Doacoes',
              style: const pw.TextStyle(
                color: PdfColors.grey600,
                fontSize: 10,
              ),
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Pagina ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(
                color: PdfColors.grey600,
                fontSize: 10,
              ),
            ),
          );
        },
        build: (context) {
          return [
            // Cabecalho do relatorio.
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: _verdeClaro,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Connect ONG',
                    style: pw.TextStyle(
                      color: _verdeMarca,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Historico de Doacoes',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (nomeDoador != null && nomeDoador.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Doador: ${nomeDoador.trim()}',
                      style: const pw.TextStyle(fontSize: 13),
                    ),
                  ],
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Gerado em: $dataGeracao',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // ----- Secao 1: doacoes financeiras via PIX -----
            pw.SizedBox(height: 20),
            _tituloSecao('Doacoes via PIX'),
            pw.SizedBox(height: 8),
            if (linhasPix.isEmpty)
              pw.Text(
                'Nenhuma doacao via PIX registrada.',
                style: const pw.TextStyle(fontSize: 12),
              )
            else ...[
              _tabela(
                headers: const ['Data', 'ONG', 'Valor'],
                data: linhasPix,
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.2),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(1.2),
                },
                alinhamentos: const {2: pw.Alignment.centerRight},
              ),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total doado via PIX: '
                  'R\$ ${totalPix.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _verdeMarca,
                  ),
                ),
              ),
            ],

            // ----- Secao 2: itens doados (matches aceitos) -----
            pw.SizedBox(height: 20),
            _tituloSecao('Itens doados (matches aceitos)'),
            pw.SizedBox(height: 8),
            if (linhasItens.isEmpty)
              pw.Text(
                'Nenhum item doado por match ate o momento.',
                style: const pw.TextStyle(fontSize: 12),
              )
            else
              _tabela(
                headers: const ['Item / necessidade atendida', 'ONG'],
                data: linhasItens,
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                },
              ),

            // ----- Resumo final -----
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total de doacoes: ${doacoesPix.length + itensDoados.length} '
              '(${doacoesPix.length} via PIX, ${itensDoados.length} em itens)',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _verdeMarca,
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _tituloSecao(String titulo) {
    return pw.Text(
      titulo,
      style: pw.TextStyle(
        fontSize: 15,
        fontWeight: pw.FontWeight.bold,
        color: _verdeMarca,
      ),
    );
  }

  // Tabela zebrada no padrao visual da marca.
  static pw.Widget _tabela({
    required List<String> headers,
    required List<List<String>> data,
    Map<int, pw.TableColumnWidth>? columnWidths,
    Map<int, pw.Alignment>? alinhamentos,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 0.5,
      ),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: _verdeMarca,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: alinhamentos ?? const {},
      rowDecoration: const pw.BoxDecoration(
        color: PdfColors.white,
      ),
      oddRowDecoration: const pw.BoxDecoration(
        color: _verdeClaro,
      ),
      columnWidths: columnWidths,
    );
  }

  static String _formatarDataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }
}
