/// Uma doação financeira (PIX simulado) feita pelo doador a uma ONG.
///
/// Espelha o DoacaoFinanceiraResponseDTO do backend
/// (`GET /doacoes-financeiras?doadorId=`): id, ONG, valor, status e data.
class DoacaoFinanceira {
  final int id;
  final int? ongId;
  final String ongNome;
  final double valor;
  final String status;
  final DateTime? dataCriacao;

  const DoacaoFinanceira({
    required this.id,
    this.ongId,
    required this.ongNome,
    required this.valor,
    required this.status,
    this.dataCriacao,
  });

  factory DoacaoFinanceira.fromJson(Map<String, dynamic> json) {
    return DoacaoFinanceira(
      id: json['id'],
      ongId: json['ongId'],
      ongNome: json['ongNome'] ?? 'ONG',
      // O backend serializa como número (pode vir int, ex.: 50).
      valor: (json['valor'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? '',
      // LocalDateTime vem como ISO-8601 ("2026-07-02T15:30:00").
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.tryParse(json['dataCriacao'].toString())
          : null,
    );
  }

  /// Valor formatado em reais (ex.: "R$ 50,00").
  String get valorFormatado =>
      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

  /// Data formatada (ex.: "02/07/2026") ou '—' quando ausente.
  String get dataFormatada {
    final d = dataCriacao;
    if (d == null) return '—';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }
}
