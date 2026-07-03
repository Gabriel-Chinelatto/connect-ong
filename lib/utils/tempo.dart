/// Helpers de tempo/apresentação de datas do app (sem pacotes externos).
///
/// Centraliza a formatação do "visto por último" do chat (que agora usa o
/// `ultimoVistoEpoch` em millis UTC vindo do servidor, à prova de fuso) e o
/// "Membro desde `mês/ano`" do perfil público.
library;

/// Converte o epoch em millis (UTC) vindo do servidor para um [DateTime]
/// LOCAL. Devolve null quando o servidor não informou o campo (contas/chats
/// antigos) — o chamador degrada graciosamente.
DateTime? dataLocalDeEpoch(int? millis) {
  if (millis == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis);
}

/// Texto de presença do chat, nas 4 faixas combinadas:
/// - [online] verdadeiro (calculado NO SERVIDOR) → "online";
/// - visto HOJE → "visto por último às HH:mm";
/// - visto ONTEM → "visto por último ontem às HH:mm";
/// - mais antigo → "visto por último em dd/MM às HH:mm".
///
/// [ultimoVisto] deve estar no fuso LOCAL (use [dataLocalDeEpoch]). Sem
/// informação (null e offline) devolve string vazia — a UI simplesmente não
/// mostra a linha. [agora] existe para os testes serem determinísticos.
String textoVistoPorUltimo({
  required bool online,
  DateTime? ultimoVisto,
  DateTime? agora,
}) {
  if (online) return 'online';
  if (ultimoVisto == null) return '';

  final ref = agora ?? DateTime.now();
  final hoje = DateTime(ref.year, ref.month, ref.day);
  final dia =
      DateTime(ultimoVisto.year, ultimoVisto.month, ultimoVisto.day);

  final hh = ultimoVisto.hour.toString().padLeft(2, '0');
  final mm = ultimoVisto.minute.toString().padLeft(2, '0');

  if (dia == hoje) return 'visto por último às $hh:$mm';
  if (dia == hoje.subtract(const Duration(days: 1))) {
    return 'visto por último ontem às $hh:$mm';
  }
  final dd = ultimoVisto.day.toString().padLeft(2, '0');
  final mes = ultimoVisto.month.toString().padLeft(2, '0');
  return 'visto por último em $dd/$mes às $hh:$mm';
}

const List<String> _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "julho de 2026" — usado no "Membro desde `mês/ano`" do perfil público.
String mesAnoPorExtenso(DateTime data) =>
    '${_meses[data.month - 1]} de ${data.year}';

/// "2026-07-03T10:20:00" → "03/07/2026". Datas ausentes/inesperadas degradam
/// para string vazia (contas antigas sem o campo).
String dataCurtaDeIso(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final soData = iso.split('T').first;
  final partes = soData.split('-');
  if (partes.length != 3) return soData;
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}
