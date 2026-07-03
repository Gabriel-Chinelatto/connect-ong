import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/mensagem.dart';
import 'package:flutter_application_1/models/perfil_publico_doador.dart';
import 'package:flutter_application_1/models/perfil_publico_ong.dart';
import 'package:flutter_application_1/models/prestacao.dart';
import 'package:flutter_application_1/models/ranking_ong.dart';
import 'package:flutter_application_1/utils/app_links.dart';

/// Testes de CONTRATO dos campos novos do backend (commit f7198d5): garantem
/// que os modelos parseiam o payload rico E degradam graciosamente quando os
/// campos vierem ausentes (contas/dados antigos).
void main() {
  group('PerfilPublicoDoador', () {
    test('parse completo (payload do backend f7198d5)', () {
      final p = PerfilPublicoDoador.fromJson({
        'id': 7,
        'nome': 'Ana',
        'cidade': 'Assis',
        'estado': 'SP',
        'fotoBase64': 'QUJD',
        'membroDesde': '2025-03-10T08:00:00',
        'notaMediaDoador': 4.9,
        'totalAvaliacoesDoador': 3,
        'stats': {'matchesConcluidos': 5, 'totalDoacoesPix': 2},
        'avaliacoes': [
          {
            'ongNome': 'Lar Feliz',
            'nota': 5,
            'comentario': 'Doador exemplar',
            'criadoEm': '2026-06-01T10:00:00',
          }
        ],
        'prestacoesRecebidas': [
          {
            'titulo': 'Compra de ração',
            'descricao': 'Usamos tudo',
            'ongNome': 'Lar Feliz',
            'necessidadeTitulo': 'Ração',
            'criadoEm': '2026-06-02T10:00:00',
          }
        ],
      });
      expect(p.nome, 'Ana');
      expect(p.matchesConcluidos, 5);
      expect(p.totalDoacoesPix, 2);
      expect(p.avaliacoes.single.ongNome, 'Lar Feliz');
      expect(p.prestacoesRecebidas.single.necessidadeTitulo, 'Ração');
      expect(p.doadorCincoEstrelas, isTrue); // 4.9 >= 4.8 com 3 avaliações
    });

    test('conta antiga: campos opcionais ausentes não quebram', () {
      final p = PerfilPublicoDoador.fromJson({'id': 1, 'nome': 'Zé'});
      expect(p.membroDesde, isNull);
      expect(p.fotoBase64, isEmpty);
      expect(p.matchesConcluidos, 0);
      expect(p.avaliacoes, isEmpty);
      expect(p.doadorCincoEstrelas, isFalse); // sem avaliações não há badge
    });

    test('badge exige nota >= 4.8 E pelo menos 1 avaliação', () {
      final semAvaliacao = PerfilPublicoDoador.fromJson(
          {'id': 1, 'nome': 'A', 'notaMediaDoador': 5.0});
      expect(semAvaliacao.doadorCincoEstrelas, isFalse);
      final notaBaixa = PerfilPublicoDoador.fromJson({
        'id': 1,
        'nome': 'A',
        'notaMediaDoador': 4.7,
        'totalAvaliacoesDoador': 10,
      });
      expect(notaBaixa.doadorCincoEstrelas, isFalse);
    });
  });

  group('PerfilPublicoOng — campos ricos', () {
    test('parse de capa, endereço, fotosLocal e streak', () {
      final p = PerfilPublicoOng.fromJson({
        'id': 3,
        'nome': 'ONG X',
        'capaBase64': 'QUJD',
        'endereco': 'Rua das Flores, 123',
        'fotosLocal': ['QUJD', 'REVG', ''],
        'diasNoTopo': 4,
        'ultimoReinadoDias': 9,
      });
      expect(p.capaBase64, 'QUJD');
      expect(p.endereco, 'Rua das Flores, 123');
      expect(p.fotosLocal, ['QUJD', 'REVG']); // vazias são filtradas
      expect(p.diasNoTopo, 4);
      expect(p.ultimoReinadoDias, 9);
    });

    test('ONG antiga sem os campos novos', () {
      final p = PerfilPublicoOng.fromJson({'id': 3, 'nome': 'ONG X'});
      expect(p.capaBase64, isNull);
      expect(p.fotosLocal, isEmpty);
      expect(p.diasNoTopo, isNull);
      expect(p.ultimoReinadoDias, isNull);
    });
  });

  group('RankingOng — diasNoTopo', () {
    test('item #1 traz o streak; demais vêm null', () {
      final top1 = RankingOng.fromJson(
          {'ongId': 1, 'nome': 'A', 'diasNoTopo': 12});
      final outra = RankingOng.fromJson({'ongId': 2, 'nome': 'B'});
      expect(top1.diasNoTopo, 12);
      expect(outra.diasNoTopo, isNull);
    });
  });

  group('Prestacao — payload rico', () {
    test('parse de fotos, valorUtilizado e vínculos', () {
      final p = Prestacao.fromJson({
        'id': 10,
        'titulo': 'Compra de cestas',
        'descricao': 'Relato',
        'doadorId': 7,
        'doadorNome': 'Ana',
        'ongNome': 'Lar Feliz',
        'necessidadeTitulo': 'Cestas básicas',
        'fotos': ['QUJD', 'REVG'],
        'valorUtilizado': 150.5,
      });
      expect(p.fotos, hasLength(2));
      expect(p.valorUtilizado, 150.5);
      expect(p.ongNome, 'Lar Feliz');
      expect(p.doadorId, 7);
    });

    test('prestação antiga: sem fotos/valor não quebra', () {
      final p = Prestacao.fromJson({'id': 1, 'titulo': 'T'});
      expect(p.fotos, isEmpty);
      expect(p.valorUtilizado, isNull);
      expect(p.necessidadeTitulo, isNull);
    });
  });

  group('Mensagem — anexo de imagem', () {
    test('anexoBase64 + anexoTipo imagem → temImagem', () {
      final m = Mensagem.fromJson({
        'id': 1,
        'remetente': 'ONG',
        'conteudo': '',
        'anexoBase64': 'QUJD',
        'anexoTipo': 'imagem',
      });
      expect(m.temImagem, isTrue);
      expect(m.conteudo, isEmpty); // texto vazio é permitido com anexo
    });

    test('mensagem só de texto → sem imagem', () {
      final m = Mensagem.fromJson(
          {'id': 2, 'remetente': 'DOADOR', 'conteudo': 'oi'});
      expect(m.temImagem, isFalse);
    });
  });

  group('app_links', () {
    test('linkPerfilOng monta a URL do app web', () {
      expect(linkPerfilOng(12), '$baseUrl/#/ong/12');
      expect(linkPerfilOng(12), 'http://localhost:5100/#/ong/12');
    });
  });
}
