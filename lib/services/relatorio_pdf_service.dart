import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../doacao.dart';

/// Gera relatorios em PDF a partir dos dados ja carregados no app.
///
/// Nao depende de novos endpoints: recebe a lista de [Doacao] que a tela
/// Minhas Doacoes ja possui em memoria.
class RelatorioPdfService {
  RelatorioPdfService._();

  static const PdfColor _verdeMarca = PdfColor.fromInt(0xFF0A8449);
  static const PdfColor _verdeClaro = PdfColor.fromInt(0xFFEAF6EE);

  /// Monta o PDF do historico de doacoes e devolve os bytes prontos
  /// para compartilhar/imprimir via package `printing`.
  static Future<Uint8List> historicoDoacoes(
    List<Doacao> doacoes, {
    String? nomeDoador,
  }) async {
    final doc = pw.Document();

    final agora = DateTime.now();
    final dataGeracao = _formatarDataHora(agora);

    final linhas = doacoes.map((d) {
      return <String>[
        d.nome,
        d.descricao,
        d.quantidade.toString(),
        d.categoria,
        d.tipo,
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
            pw.SizedBox(height: 20),
            if (linhas.isEmpty)
              pw.Text(
                'Nenhuma doacao cadastrada.',
                style: const pw.TextStyle(fontSize: 13),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Item',
                  'Descricao',
                  'Qtd',
                  'Categoria',
                  'Tipo',
                ],
                data: linhas,
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
                cellAlignments: const {
                  2: pw.Alignment.center,
                },
                rowDecoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                ),
                oddRowDecoration: const pw.BoxDecoration(
                  color: _verdeClaro,
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.2),
                  1: pw.FlexColumnWidth(3.5),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(2),
                  4: pw.FlexColumnWidth(1.6),
                },
              ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total de doacoes: ${doacoes.length}',
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

  static String _formatarDataHora(DateTime d) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }
}
