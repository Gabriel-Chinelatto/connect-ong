import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/utils/formatters.dart';
import 'package:flutter_application_1/utils/tempo.dart';

void main() {
  group('textoVistoPorUltimo — as 4 faixas do chat', () {
    // "Agora" fixo para os testes serem determinísticos:
    // sexta, 03/07/2026 às 15:00 (hora local).
    final agora = DateTime(2026, 7, 3, 15, 0);

    test('online → "online" (ignora o ultimoVisto)', () {
      expect(
        textoVistoPorUltimo(
          online: true,
          ultimoVisto: DateTime(2026, 7, 1, 9, 30),
          agora: agora,
        ),
        'online',
      );
    });

    test('visto HOJE → "visto por último às HH:mm"', () {
      expect(
        textoVistoPorUltimo(
          online: false,
          ultimoVisto: DateTime(2026, 7, 3, 9, 5),
          agora: agora,
        ),
        'visto por último às 09:05',
      );
    });

    test('visto ONTEM → "visto por último ontem às HH:mm"', () {
      expect(
        textoVistoPorUltimo(
          online: false,
          ultimoVisto: DateTime(2026, 7, 2, 23, 59),
          agora: agora,
        ),
        'visto por último ontem às 23:59',
      );
    });

    test('mais antigo → "visto por último em dd/MM às HH:mm"', () {
      expect(
        textoVistoPorUltimo(
          online: false,
          ultimoVisto: DateTime(2026, 6, 28, 7, 45),
          agora: agora,
        ),
        'visto por último em 28/06 às 07:45',
      );
    });

    test('sem informação (offline e sem ultimoVisto) → vazio', () {
      expect(textoVistoPorUltimo(online: false, agora: agora), '');
    });

    test('virada de mês/ano: 01/01 tem ontem em 31/12', () {
      final anoNovo = DateTime(2027, 1, 1, 0, 10);
      expect(
        textoVistoPorUltimo(
          online: false,
          ultimoVisto: DateTime(2026, 12, 31, 23, 58),
          agora: anoNovo,
        ),
        'visto por último ontem às 23:58',
      );
    });
  });

  group('dataLocalDeEpoch', () {
    test('null → null (contas/chats antigos sem o campo)', () {
      expect(dataLocalDeEpoch(null), isNull);
    });

    test('converte millis para DateTime local equivalente ao instante UTC',
        () {
      final millis =
          DateTime.utc(2026, 7, 3, 12, 0).millisecondsSinceEpoch;
      final local = dataLocalDeEpoch(millis)!;
      // O instante é o mesmo, independentemente do fuso da máquina.
      expect(local.toUtc(), DateTime.utc(2026, 7, 3, 12, 0));
    });
  });

  group('mesAnoPorExtenso', () {
    test('julho de 2026', () {
      expect(mesAnoPorExtenso(DateTime(2026, 7, 15)), 'julho de 2026');
    });
    test('janeiro e dezembro (bordas da lista de meses)', () {
      expect(mesAnoPorExtenso(DateTime(2025, 1, 1)), 'janeiro de 2025');
      expect(mesAnoPorExtenso(DateTime(2025, 12, 31)), 'dezembro de 2025');
    });
  });

  group('dataCurtaDeIso', () {
    test('ISO completa → dd/MM/yyyy', () {
      expect(dataCurtaDeIso('2026-07-03T10:20:00'), '03/07/2026');
    });
    test('null/vazio → vazio', () {
      expect(dataCurtaDeIso(null), '');
      expect(dataCurtaDeIso(''), '');
    });
  });

  group('formatarReais', () {
    test('valores comuns', () {
      expect(formatarReais(0), 'R\$ 0,00');
      expect(formatarReais(5), 'R\$ 5,00');
      expect(formatarReais(1234.5), 'R\$ 1.234,50');
      expect(formatarReais(1234567.89), 'R\$ 1.234.567,89');
    });
    test('arredondamento de centavos', () {
      expect(formatarReais(9.999), 'R\$ 10,00');
    });
  });
}
