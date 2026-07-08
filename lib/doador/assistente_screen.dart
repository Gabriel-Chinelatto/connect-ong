import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/necessidade.dart';
import '../services/assistente_service.dart';
import '../services/conversas_dora_service.dart';
import '../services/perfil_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/tempo.dart';
import '../widgets/common/dora_avatar.dart';
import '../widgets/common/visualizador_imagem.dart';
import '../widgets/feedback/app_snackbar.dart';
import 'necessidade_detalhe_screen.dart';
import 'perfil_publico_ong_screen.dart';

/// Papel de uma bolha na conversa local.
enum _Papel { usuario, assistente, erro }

/// Uma bolha exibida na tela (mensagem do usuario, da Dora, ou um erro de rede
/// com botao de "tentar de novo").
class _Bolha {
  final _Papel papel;
  final String texto;
  final List<SugestaoAssistente> sugestoes;

  /// Miniatura da foto anexada pelo usuario (quando ele mandou uma imagem para
  /// a Dora analisar). So nas bolhas do usuario.
  final Uint8List? imagemBytes;

  /// A mesma foto em base64 — persistida no historico para reaparecer ao
  /// reabrir a conversa. So nas bolhas do usuario.
  final String? imagemBase64;

  /// Preenchido apenas nas bolhas de erro: a pergunta que falhou, para o
  /// botao "tentar de novo" reenviar exatamente ela.
  final String? perguntaOriginal;

  /// A imagem (base64) que acompanhava a pergunta que falhou, para reenviar.
  final String? imagemOriginal;

  /// Modo em que a Dora respondeu ('regras' mostra o selo "Modo basico").
  final bool modoRegras;

  const _Bolha({
    required this.papel,
    required this.texto,
    this.sugestoes = const [],
    this.imagemBytes,
    this.imagemBase64,
    this.perguntaOriginal,
    this.imagemOriginal,
    this.modoRegras = false,
  });
}

/// Chat da Dora — a assistente de doacao do Connect ONG (estilo ChatGPT com
/// historico persistente).
///
/// A Dora ajuda o doador a decidir para quem doar ("tenho roupas e nao sei pra
/// quem"), a achar ONGs perto dele e a entender como a doacao funciona.
/// Conversa com `POST /assistente` (via [AssistenteService]) mandando a cidade
/// do doador (do perfil), as ultimas ~6 trocas DESTA conversa (isolamento — uma
/// conversa nao contamina a outra) e, quando o doador anexa uma foto, a imagem
/// em base64 para a Dora "analisar".
///
/// As conversas sao guardadas LOCALMENTE (via [ConversasDoraService]) e
/// reabertas ao voltar para a tela. Um Drawer lateral lista o historico
/// (fixar/renomear/excluir/buscar), estilo ChatGPT. Quando a resposta traz
/// sugestoes, elas viram cards clicaveis que abrem o perfil da ONG ou o detalhe
/// da necessidade. Degrada com bolha de erro + "tentar de novo".
class AssistenteScreen extends StatefulWidget {
  /// Abre o Drawer de historico automaticamente ao iniciar. Usado por
  /// deep-links/harness de verificacao visual; no fluxo normal fica false.
  final bool abrirHistoricoAoIniciar;

  const AssistenteScreen({super.key, this.abrirHistoricoAoIniciar = false});

  @override
  State<AssistenteScreen> createState() => _AssistenteScreenState();
}

class _AssistenteScreenState extends State<AssistenteScreen> {
  final AssistenteService _service = AssistenteService();
  final ConversasDoraService _conversasService = ConversasDoraService();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _buscaController = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Enter envia / Shift+Enter quebra linha (web/desktop) — ver [_aoTeclar].
  late final FocusNode _campoFocus = FocusNode(onKeyEvent: _aoTeclar);

  // Bolhas REAIS da conversa atual (a bolha de boas-vindas e renderizada a
  // parte, sempre no topo, e nunca persistida).
  final List<_Bolha> _bolhas = [];

  // Conversa atualmente aberta (nova e vazia ate a 1a mensagem do usuario).
  ConversaDora _conversa = ConversaDora.nova();
  // Lista de conversas do historico (para o Drawer), ja ordenada pelo service.
  List<ConversaDora> _conversas = [];
  String _busca = '';

  bool _enviando = false; // guard anti-duplo-toque + indicador da Dora
  bool _analisandoImagem = false; // indicador "analisando a imagem..."
  String? _cidade; // cidade do doador (do perfil), enviada no request

  // Foto anexada PENDENTE (escolhida, ainda nao enviada) + guard do picker.
  Uint8List? _anexoBytes;
  String? _anexoBase64;
  bool _abrindoGaleria = false;

  // Chips de sugestao de pergunta (mostrados so no inicio, antes da 1ª troca).
  static const List<(IconData, String)> _chipsIniciais = [
    (Icons.checkroom, 'Tenho roupas para doar'),
    (Icons.location_on_outlined, 'ONGs perto de mim'),
    (Icons.pets, 'Quero ajudar animais'),
    (Icons.help_outline, 'Como funciona a doacao?'),
  ];

  @override
  void initState() {
    super.initState();
    _carregarCidade();
    _restaurar();
  }

  @override
  void dispose() {
    _controller.dispose();
    _buscaController.dispose();
    _scroll.dispose();
    _campoFocus.dispose();
    super.dispose();
  }

  /// Restaura a ULTIMA conversa aberta do storage (ou comeca uma nova vazia se
  /// nao houver) e carrega a lista do historico para o Drawer.
  Future<void> _restaurar() async {
    final ultima = await _conversasService.obterUltima();
    if (!mounted) return;
    setState(() {
      if (ultima != null) {
        _conversa = ultima;
        _reconstruirBolhas();
      }
    });
    await _carregarConversas();
    _irParaOFim();
    if (widget.abrirHistoricoAoIniciar && mounted) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scaffoldKey.currentState?.openDrawer(),
      );
    }
  }

  /// Recarrega a lista de conversas (usada apos qualquer CRUD do historico).
  Future<void> _carregarConversas() async {
    final lista = await _conversasService.listar();
    if (!mounted) return;
    setState(() => _conversas = lista);
  }

  /// Reconstroi as bolhas da UI a partir das mensagens persistidas da conversa
  /// atual (decodifica a foto base64 de volta para bytes, para exibir).
  void _reconstruirBolhas() {
    _bolhas
      ..clear()
      ..addAll(_conversa.mensagens.map(_mensagemParaBolha));
  }

  _Bolha _mensagemParaBolha(MensagemDora m) {
    Uint8List? bytes;
    final b64 = m.imagemBase64;
    if (b64 != null && b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        // base64 corrompido: mostra so o texto, sem quebrar.
      }
    }
    return _Bolha(
      papel: m.ehUsuario ? _Papel.usuario : _Papel.assistente,
      texto: m.texto,
      sugestoes: m.sugestoes,
      imagemBytes: bytes,
      imagemBase64: b64,
      modoRegras: m.modoRegras,
    );
  }

  MensagemDora _bolhaParaMensagem(_Bolha b) => MensagemDora(
        papel: b.papel == _Papel.usuario ? 'user' : 'assistente',
        texto: b.texto,
        imagemBase64: b.imagemBase64,
        sugestoes: b.sugestoes,
        modoRegras: b.modoRegras,
      );

  /// Autosave: transfere as bolhas reais (sem erros) para a conversa atual,
  /// salva no storage e a marca como a ultima aberta.
  Future<void> _persistir() async {
    _conversa.mensagens
      ..clear()
      ..addAll(
        _bolhas.where((b) => b.papel != _Papel.erro).map(_bolhaParaMensagem),
      );
    _conversa.atualizadoEm = DateTime.now();
    await _conversasService.salvar(_conversa);
    await _conversasService.definirUltima(_conversa.id);
    await _carregarConversas();
  }

  /// Enter (sem Shift) envia; Shift+Enter deixa o campo inserir a quebra de
  /// linha normalmente. Vale no Flutter web/desktop; em teclado de toque o
  /// comportamento do sistema prevalece.
  KeyEventResult _aoTeclar(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _enviar(_controller.text);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Cidade do doador vem do perfil (GET /usuarios/{id}/perfil, campo cidade).
  /// Best-effort: qualquer falha degrada para null (o request vai sem cidade).
  Future<void> _carregarCidade() async {
    try {
      final usuario = await SessionService().obterUsuario();
      if (usuario == null) return;
      final perfil = await PerfilService().obter(usuario.id);
      final cidade = (perfil['cidade'] ?? '').toString().trim();
      if (!mounted) return;
      if (cidade.isNotEmpty) setState(() => _cidade = cidade);
    } catch (_) {
      // Sem cidade: segue a vida, a Dora ainda responde.
    }
  }

  /// Monta o historico recente (ultimas ~6 trocas de user/assistente DESTA
  /// conversa, sem as bolhas de erro) no formato do contrato: {papel, texto}.
  List<Map<String, String>> _historico() {
    final trocas = _bolhas
        .where((b) => b.papel != _Papel.erro)
        .map((b) => {
              'papel': b.papel == _Papel.usuario ? 'user' : 'assistente',
              'texto': b.texto,
            })
        .toList();
    if (trocas.length <= 6) return trocas;
    return trocas.sublist(trocas.length - 6);
  }

  Future<void> _enviar(String texto,
      {String? imagemBase64, Uint8List? imagemBytes}) async {
    final mensagem = texto.trim();
    // Anexo atual (parametro tem prioridade — usado no "tentar de novo").
    final imgB64 = imagemBase64 ?? _anexoBase64;
    final imgBytes = imagemBytes ?? _anexoBytes;
    final temImagem = imgB64 != null && imgB64.isNotEmpty;
    // Pode enviar so texto, so imagem, ou os dois — mas nunca nada.
    if ((mensagem.isEmpty && !temImagem) || _enviando) return;

    // Historico ANTES de adicionar a mensagem atual (a mensagem vai no campo
    // "mensagem" do request, nao no historico).
    final historico = _historico();
    // Se veio so imagem, manda um texto padrao para a Dora saber o que fazer.
    final mensagemEnviada = mensagem.isNotEmpty
        ? mensagem
        : 'Dei uma olhada nesta foto — o que voce acha? Serve para doar?';

    setState(() {
      _bolhas.add(_Bolha(
        papel: _Papel.usuario,
        texto: mensagem,
        imagemBytes: temImagem ? imgBytes : null,
        imagemBase64: temImagem ? imgB64 : null,
      ));
      _enviando = true;
      _analisandoImagem = temImagem;
      _controller.clear();
      _anexoBytes = null;
      _anexoBase64 = null;
    });
    _irParaOFim();

    try {
      final resposta = await _service.perguntar(
        mensagem: mensagemEnviada,
        historico: historico,
        cidade: _cidade,
        imagemBase64: temImagem ? imgB64 : null,
      );
      if (!mounted) return;
      setState(() {
        _bolhas.add(_Bolha(
          papel: _Papel.assistente,
          texto: resposta.resposta.isNotEmpty
              ? resposta.resposta
              : 'Nao consegui uma resposta agora. Pode reformular?',
          sugestoes: resposta.sugestoes,
          modoRegras: resposta.modoRegras,
        ));
        // Titulo da conversa: definido na 1a resposta. Usa o do backend se
        // vier; senao deriva da 1a mensagem do usuario. Dedupe contra as
        // conversas existentes. Renomear manual sobrepoe (nao mexe depois).
        if (_conversa.titulo.trim().isEmpty) {
          final primeira = _bolhas
              .firstWhere((b) => b.papel == _Papel.usuario,
                  orElse: () => const _Bolha(papel: _Papel.usuario, texto: ''))
              .texto;
          final base = resposta.titulo.isNotEmpty
              ? resposta.titulo
              : (primeira.trim().isNotEmpty
                  ? ConversasDoraService.tituloDerivado(primeira)
                  : 'Foto para doar');
          _conversa.titulo = ConversasDoraService.tituloUnico(
            base,
            _conversas,
            ignorarId: _conversa.id,
          );
        }
      });
      await _persistir();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bolhas.add(_Bolha(
          papel: _Papel.erro,
          texto: e.toString().replaceFirst('Exception: ', ''),
          perguntaOriginal: mensagem,
          imagemOriginal: temImagem ? imgB64 : null,
          imagemBytes: temImagem ? imgBytes : null,
        ));
      });
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
          _analisandoImagem = false;
        });
      }
      _irParaOFim();
    }
  }

  /// Escolhe uma foto da galeria para a Dora analisar (resize ~1024, qualidade
  /// 70 → base64). Fica pendente como preview ate o doador enviar.
  Future<void> _escolherAnexo() async {
    if (_abrindoGaleria || _enviando) return; // anti-duplo-toque
    _abrindoGaleria = true;
    try {
      final XFile? img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (img == null) return;
      final bytes = await img.readAsBytes();
      if (!mounted) return;
      setState(() {
        _anexoBytes = bytes;
        _anexoBase64 = base64Encode(bytes);
      });
    } catch (_) {
      if (mounted) {
        AppSnackbar.erro(context, 'Nao foi possivel abrir a galeria.');
      }
    } finally {
      _abrindoGaleria = false;
    }
  }

  /// Reenvia a pergunta que falhou (botao "tentar de novo" da bolha de erro):
  /// remove a bolha de erro e a bolha do usuario que a originou, e reenvia
  /// (com a mesma foto, se havia).
  void _tentarDeNovo(_Bolha erro) {
    if (_enviando) return;
    setState(() {
      final idxErro = _bolhas.lastIndexWhere((b) => b.papel == _Papel.erro);
      if (idxErro != -1) _bolhas.removeAt(idxErro);
      final idxUser =
          _bolhas.lastIndexWhere((b) => b.papel == _Papel.usuario);
      if (idxUser != -1) _bolhas.removeAt(idxUser);
    });
    _enviar(
      erro.perguntaOriginal ?? '',
      imagemBase64: erro.imagemOriginal,
      imagemBytes: erro.imagemBytes,
    );
  }

  void _irParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---- Acoes do historico (Drawer) ----

  /// Abre uma nova conversa vazia (nao persiste ate a 1a mensagem).
  void _novaConversa() {
    _scaffoldKey.currentState?.closeDrawer();
    if (!_conversa.temMensagemDoUsuario && _bolhas.isEmpty) return; // ja vazia
    setState(() {
      _conversa = ConversaDora.nova();
      _bolhas.clear();
      _busca = '';
      _buscaController.clear();
    });
  }

  /// Abre uma conversa existente do historico.
  void _abrirConversa(ConversaDora c) {
    _scaffoldKey.currentState?.closeDrawer();
    if (c.id == _conversa.id) return;
    setState(() {
      _conversa = c;
      _reconstruirBolhas();
    });
    _conversasService.definirUltima(c.id);
    _irParaOFim();
  }

  Future<void> _alternarFixado(ConversaDora c) async {
    await _conversasService.alternarFixado(c.id);
    if (c.id == _conversa.id) _conversa.fixado = !_conversa.fixado;
    await _carregarConversas();
  }

  Future<void> _renomear(ConversaDora c) async {
    final ctrl = TextEditingController(text: c.tituloExibicao);
    final novo = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Renomear conversa'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 60,
            decoration: InputDecoration(
              hintText: 'Nome da conversa',
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: AppRadius.brMd,
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    if (novo == null || novo.trim().isEmpty) return;
    await _conversasService.renomear(c.id, novo.trim());
    if (c.id == _conversa.id) _conversa.titulo = novo.trim();
    await _carregarConversas();
  }

  Future<void> _excluir(ConversaDora c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conversa'),
        content: Text(
          'Excluir "${c.tituloExibicao}"? Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _conversasService.excluir(c.id);
    if (c.id == _conversa.id) {
      setState(() {
        _conversa = ConversaDora.nova();
        _bolhas.clear();
      });
    }
    await _carregarConversas();
  }

  // ---- Navegacao a partir dos cards de sugestao ----
  void _abrirSugestao(SugestaoAssistente s) {
    if (s.id == null) return; // sem id nao da para abrir — degrada em silencio.
    if (s.ehOng) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PerfilPublicoOngScreen(ongId: s.id!, ongNome: s.titulo),
        ),
      );
    } else if (s.ehNecessidade) {
      final necessidade = Necessidade(
        id: s.id!,
        titulo: s.titulo,
        descricao: s.subtitulo,
        categoria: '',
        urgente: false,
        status: 'ABERTA',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NecessidadeDetalheScreen(necessidade: necessidade),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mostrarIndicador = _enviando;
    // itemCount: bolha de boas-vindas (1) + bolhas reais + indicador.
    final itemCount = 1 + _bolhas.length + (mostrarIndicador ? 1 : 0);
    // Chips so aparecem no comeco (antes de qualquer troca real).
    final mostrarChips =
        _bolhas.where((b) => b.papel == _Papel.usuario).isEmpty && !_enviando;
    // Subtitulo do cabecalho: o titulo da conversa quando ja existe.
    final subtitulo = _conversa.titulo.trim().isNotEmpty
        ? _conversa.titulo.trim()
        : 'Sua assistente de doacao';
    // Fundo sutil da conversa (estilo WhatsApp): um tom levemente esverdeado.
    final fundoConversa = Color.alphaBlend(
      AppColors.primary.withValues(alpha: 0.04),
      cs.surface,
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: _construirDrawer(cs),
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Voltar ao início',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            const DoraAvatar(tamanho: 38),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dora',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitulo,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Conversas',
            icon: const Icon(Icons.history),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          IconButton(
            tooltip: 'Nova conversa',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _novaConversa,
          ),
        ],
      ),
      body: Container(
        color: fundoConversa,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                itemCount: itemCount,
                itemBuilder: (context, i) {
                  if (i == 0) return _bolhaBoasVindas(cs);
                  final idx = i - 1;
                  if (mostrarIndicador && idx == _bolhas.length) {
                    return _bolhaDigitando(cs);
                  }
                  return _construirBolha(_bolhas[idx], cs);
                },
              ),
            ),
            if (mostrarChips) _chips(cs),
            _previewAnexo(cs),
            _campoEnvio(cs),
          ],
        ),
      ),
    );
  }

  // ---- Drawer / historico (estilo ChatGPT) ----
  Widget _construirDrawer(ColorScheme cs) {
    final q = _busca.trim().toLowerCase();
    final filtradas = q.isEmpty
        ? _conversas
        : _conversas.where((c) {
            if (c.tituloExibicao.toLowerCase().contains(q)) return true;
            return c.mensagens.any((m) => m.texto.toLowerCase().contains(q));
          }).toList();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    'Conversas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Nova conversa',
                    icon: const Icon(Icons.add),
                    onPressed: _novaConversa,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _buscaController,
                onChanged: (v) => setState(() => _busca = v),
                decoration: InputDecoration(
                  hintText: 'Buscar conversas',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _busca.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _buscaController.clear();
                            setState(() => _busca = '');
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: filtradas.isEmpty
                  ? _historicoVazio(cs)
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      itemCount: filtradas.length,
                      itemBuilder: (_, i) => _itemConversa(filtradas[i], cs),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historicoVazio(ColorScheme cs) {
    final vazioDeVerdade = _conversas.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              vazioDeVerdade ? Icons.forum_outlined : Icons.search_off,
              size: 44,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              vazioDeVerdade
                  ? 'Nenhuma conversa ainda'
                  : 'Nenhuma conversa encontrada',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemConversa(ConversaDora c, ColorScheme cs) {
    final atual = c.id == _conversa.id;
    final data = tempoRelativo(c.atualizadoEm.toIso8601String());
    return Material(
      color: atual
          ? AppColors.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _abrirConversa(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (c.fixado)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.push_pin,
                      size: 15, color: AppColors.primary),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.tituloExibicao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.isEmpty ? c.preview : '${c.preview}  ·  $data',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opcoes',
                icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
                onSelected: (v) {
                  switch (v) {
                    case 'fixar':
                      _alternarFixado(c);
                      break;
                    case 'renomear':
                      _renomear(c);
                      break;
                    case 'excluir':
                      _excluir(c);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'fixar',
                    child: Row(
                      children: [
                        Icon(c.fixado
                            ? Icons.push_pin_outlined
                            : Icons.push_pin),
                        const SizedBox(width: AppSpacing.sm),
                        Text(c.fixado ? 'Desafixar' : 'Fixar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'renomear',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: AppSpacing.sm),
                        Text('Renomear'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'excluir',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text('Excluir', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bolha de boas-vindas da Dora — sempre no topo, nao persistida.
  Widget _bolhaBoasVindas(ColorScheme cs) {
    return _bolhaAssistenteTexto(
      cs,
      'Oi! Eu sou a Dora 💚\n\nPosso te ajudar a decidir para quem doar, '
      'achar ONGs perto de voce ou tirar duvidas sobre como doar. Pode ate '
      'me mandar a foto de um item que voce quer doar que eu dou uma olhada. '
      'Como posso ajudar?',
    );
  }

  /// Uma bolha simples de texto da Dora (sem sugestoes) — usada nas boas-vindas.
  Widget _bolhaAssistenteTexto(ColorScheme cs, String texto) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const DoraAvatar(tamanho: 28),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                texto,
                style: TextStyle(color: cs.onSurface, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBolha(_Bolha b, ColorScheme cs) {
    if (b.papel == _Papel.erro) return _bolhaErro(b, cs);

    final minha = b.papel == _Papel.usuario;
    final temTexto = b.texto.trim().isNotEmpty;

    // Bolha em si (com a foto opcional em cima do texto).
    final bolha = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: b.imagemBytes != null && !temTexto
          ? const EdgeInsets.all(4)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: minha ? AppColors.primary : cs.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(minha ? 18 : 4),
          bottomRight: Radius.circular(minha ? 4 : 18),
        ),
        border: minha ? null : Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (b.imagemBytes != null) ...[
            GestureDetector(
              onTap: () => VisualizadorImagem.abrir(context, b.imagemBytes!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, maxWidth: 240),
                  child: Image.memory(b.imagemBytes!, fit: BoxFit.cover),
                ),
              ),
            ),
            if (temTexto) const SizedBox(height: 6),
          ],
          if (temTexto)
            Padding(
              padding: b.imagemBytes != null
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : EdgeInsets.zero,
              child: Text(
                b.texto,
                style: TextStyle(
                  color: minha ? Colors.white : cs.onSurface,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment:
          minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment:
                minha ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar da Dora ao lado das bolhas dela (estilo WhatsApp).
              if (!minha) ...[
                const DoraAvatar(tamanho: 28),
                const SizedBox(width: 6),
              ],
              Flexible(child: bolha),
            ],
          ),
        ),
        // Cards de sugestao (ONG/NECESSIDADE) abaixo da bolha da Dora.
        if (b.sugestoes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md + 34,
              right: AppSpacing.md,
              top: 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final s in b.sugestoes) _cardSugestao(s, cs)],
            ),
          ),
        if (b.modoRegras)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md + 34, top: 2),
            child: Text(
              'Modo basico',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _cardSugestao(SugestaoAssistente s, ColorScheme cs) {
    final ehOng = s.ehOng;
    return Container(
      width: 300,
      margin: const EdgeInsets.only(top: 6),
      child: Material(
        color: cs.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: () => _abrirSugestao(s),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Icon(
                    ehOng ? Icons.corporate_fare : Icons.volunteer_activism,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      if (s.subtitulo.isNotEmpty)
                        Text(
                          s.subtitulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bolhaErro(_Bolha b, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const DoraAvatar(tamanho: 28),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                borderRadius: AppRadius.brMd,
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          b.texto,
                          style: TextStyle(fontSize: 13, color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _enviando ? null : () => _tentarDeNovo(b),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Tentar de novo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bolhaDigitando(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const DoraAvatar(tamanho: 28),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _analisandoImagem ? 'analisando a imagem...' : 'digitando...',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final (icone, chip) in _chipsIniciais)
            InkWell(
              borderRadius: AppRadius.brXl,
              onTap: _enviando ? null : () => _enviar(chip),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: AppRadius.brXl,
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icone, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      chip,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Preview do anexo PENDENTE (foto escolhida, ainda nao enviada), com botao
  // para remover antes de enviar.
  Widget _previewAnexo(ColorScheme cs) {
    if (_anexoBytes == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: AppRadius.brMd,
            child: Image.memory(
              _anexoBytes!,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              tooltip: 'Remover foto',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: cs.surfaceContainerHighest,
              ),
              icon: Icon(Icons.close, size: 16, color: cs.onSurface),
              onPressed: _enviando
                  ? null
                  : () => setState(() {
                        _anexoBytes = null;
                        _anexoBase64 = null;
                      }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoEnvio(ColorScheme cs) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Enviar foto para a Dora analisar',
              onPressed: _enviando ? null : _escolherAnexo,
              icon: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _campoFocus,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Pergunte alguma coisa...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brXl,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brXl,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: IconButton(
                tooltip: 'Enviar',
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _enviando ? null : () => _enviar(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
