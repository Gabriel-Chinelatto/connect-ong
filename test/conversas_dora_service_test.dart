import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/services/assistente_service.dart';
import 'package:flutter_application_1/services/conversas_dora_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Cada teste comeca com o storage local zerado.
    SharedPreferences.setMockInitialValues({});
  });

  group('tituloDerivado', () {
    test('limpa, capitaliza e nao encurta frases curtas', () {
      expect(ConversasDoraService.tituloDerivado('  tenho roupas   para doar '),
          'Tenho roupas para doar');
    });

    test('limita a ~40 chars com reticencias', () {
      final t = ConversasDoraService.tituloDerivado(
          'gostaria de doar muitas roupas de inverno e cobertores hoje');
      expect(t.length, lessThanOrEqualTo(41));
      expect(t.endsWith('…'), isTrue);
    });

    test('vazio degrada para "Nova conversa"', () {
      expect(ConversasDoraService.tituloDerivado('   '), 'Nova conversa');
    });
  });

  group('tituloUnico (dedupe)', () {
    test('sem colisao devolve o proprio titulo', () {
      final existentes = [ConversaDora.nova()..titulo = 'Outra'];
      expect(ConversasDoraService.tituloUnico('Roupas', existentes), 'Roupas');
    });

    test('colisao adiciona sufixo (2), (3)...', () {
      final existentes = [
        ConversaDora.nova()..titulo = 'Roupas',
        ConversaDora.nova()..titulo = 'Roupas (2)',
      ];
      expect(ConversasDoraService.tituloUnico('Roupas', existentes),
          'Roupas (3)');
    });

    test('ignora a propria conversa pelo id', () {
      final c = ConversaDora.nova()..titulo = 'Roupas';
      final unico =
          ConversasDoraService.tituloUnico('Roupas', [c], ignorarId: c.id);
      expect(unico, 'Roupas');
    });
  });

  group('MensagemDora/ConversaDora round-trip JSON', () {
    test('preserva texto, imagem, sugestoes e modoRegras', () {
      final m = MensagemDora(
        papel: 'assistente',
        texto: 'Perto de voce:',
        sugestoes: const [
          SugestaoAssistente(
              tipo: 'ONG', id: 3, titulo: 'Lar Viva', subtitulo: 'SP'),
        ],
        modoRegras: true,
      );
      final volta = MensagemDora.fromJson(m.toJson());
      expect(volta.texto, 'Perto de voce:');
      expect(volta.sugestoes.single.id, 3);
      expect(volta.modoRegras, isTrue);
    });

    test('imagem base64 sobrevive ao round-trip da mensagem do usuario', () {
      final m = MensagemDora(papel: 'user', texto: '', imagemBase64: 'AAAA');
      final volta = MensagemDora.fromJson(m.toJson());
      expect(volta.ehUsuario, isTrue);
      expect(volta.imagemBase64, 'AAAA');
    });
  });

  group('ConversasDoraService (SharedPreferences)', () {
    test('salvar ignora conversa sem mensagem do usuario', () async {
      final s = ConversasDoraService();
      await s.salvar(ConversaDora.nova()); // vazia
      expect(await s.listar(), isEmpty);
    });

    test('salvar persiste e listar recupera', () async {
      final s = ConversasDoraService();
      final c = ConversaDora.nova()
        ..titulo = 'Roupas'
        ..mensagens.add(const MensagemDora(papel: 'user', texto: 'oi'));
      await s.salvar(c);
      final lista = await s.listar();
      expect(lista, hasLength(1));
      expect(lista.single.titulo, 'Roupas');
    });

    test('ordena fixadas primeiro, depois por atualizadoEm desc', () async {
      final s = ConversasDoraService();
      final antiga = ConversaDora(
        id: 'a',
        titulo: 'Antiga',
        atualizadoEm: DateTime(2026, 1, 1),
        mensagens: [const MensagemDora(papel: 'user', texto: 'x')],
      );
      final nova = ConversaDora(
        id: 'b',
        titulo: 'Nova',
        atualizadoEm: DateTime(2026, 6, 1),
        mensagens: [const MensagemDora(papel: 'user', texto: 'y')],
      );
      final fixada = ConversaDora(
        id: 'c',
        titulo: 'Fixada',
        fixado: true,
        atualizadoEm: DateTime(2025, 1, 1),
        mensagens: [const MensagemDora(papel: 'user', texto: 'z')],
      );
      await s.salvar(antiga);
      await s.salvar(nova);
      await s.salvar(fixada);
      final lista = await s.listar();
      expect(lista.map((c) => c.titulo).toList(),
          ['Fixada', 'Nova', 'Antiga']);
    });

    test('renomear, fixar e excluir', () async {
      final s = ConversasDoraService();
      final c = ConversaDora.nova()
        ..titulo = 'Orig'
        ..mensagens.add(const MensagemDora(papel: 'user', texto: 'oi'));
      await s.salvar(c);

      await s.renomear(c.id, 'Novo nome');
      expect((await s.listar()).single.titulo, 'Novo nome');

      await s.alternarFixado(c.id);
      expect((await s.listar()).single.fixado, isTrue);

      await s.excluir(c.id);
      expect(await s.listar(), isEmpty);
    });

    test('definirUltima/obterUltima restaura a conversa aberta', () async {
      final s = ConversasDoraService();
      final c = ConversaDora.nova()
        ..titulo = 'Ultima'
        ..mensagens.add(const MensagemDora(papel: 'user', texto: 'oi'));
      await s.salvar(c);
      await s.definirUltima(c.id);
      final ultima = await s.obterUltima();
      expect(ultima?.titulo, 'Ultima');
    });

    test('obterUltima devolve null quando a conversa foi excluida', () async {
      final s = ConversasDoraService();
      final c = ConversaDora.nova()
        ..titulo = 'Some'
        ..mensagens.add(const MensagemDora(papel: 'user', texto: 'oi'));
      await s.salvar(c);
      await s.definirUltima(c.id);
      await s.excluir(c.id);
      expect(await s.obterUltima(), isNull);
    });
  });
}
