import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/necessidade.dart';
import '../services/assistente_service.dart';
import '../services/perfil_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
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
    this.perguntaOriginal,
    this.imagemOriginal,
    this.modoRegras = false,
  });
}

/// Chat da Dora — a assistente de doacao do Connect ONG (estilo o botao de IA
/// do iFood).
///
/// A Dora ajuda o doador a decidir para quem doar ("tenho roupas e nao sei pra
/// quem"), a achar ONGs perto dele e a entender como a doacao funciona.
/// Conversa com `POST /assistente` (via [AssistenteService]) mandando a cidade
/// do doador (do perfil), as ultimas ~6 trocas e, quando o doador anexa uma
/// foto, a imagem em base64 para a Dora "analisar". Quando a resposta traz
/// sugestoes, elas viram cards clicaveis que abrem o perfil da ONG ou o detalhe
/// da necessidade. Degrada com bolha de erro + "tentar de novo".
class AssistenteScreen extends StatefulWidget {
  const AssistenteScreen({super.key});

  @override
  State<AssistenteScreen> createState() => _AssistenteScreenState();
}

class _AssistenteScreenState extends State<AssistenteScreen> {
  final AssistenteService _service = AssistenteService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  // Enter envia / Shift+Enter quebra linha (web/desktop) — ver [_aoTeclar].
  late final FocusNode _campoFocus = FocusNode(onKeyEvent: _aoTeclar);

  final List<_Bolha> _bolhas = [];
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
    _bolhas.add(const _Bolha(
      papel: _Papel.assistente,
      texto:
          'Oi! Eu sou a Dora 💚\n\nPosso te ajudar a decidir para quem doar, '
          'achar ONGs perto de voce ou tirar duvidas sobre como doar. Pode ate '
          'me mandar a foto de um item que voce quer doar que eu dou uma olhada. '
          'Como posso ajudar?',
    ));
    _carregarCidade();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _campoFocus.dispose();
    super.dispose();
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

  /// Monta o historico recente (ultimas ~6 trocas de user/assistente, sem as
  /// bolhas de erro) no formato do contrato: {papel, texto}.
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

  Future<void> _enviar(String texto, {String? imagemBase64, Uint8List? imagemBytes}) async {
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
      });
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
    final itemCount = _bolhas.length + (mostrarIndicador ? 1 : 0);
    // Chips so aparecem no comeco (antes de qualquer troca real).
    final mostrarChips =
        _bolhas.where((b) => b.papel == _Papel.usuario).isEmpty && !_enviando;
    // Fundo sutil da conversa (estilo WhatsApp): um tom levemente esverdeado.
    final fundoConversa = Color.alphaBlend(
      AppColors.primary.withValues(alpha: 0.04),
      cs.surface,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
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
                    'Sua assistente de doacao',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  if (mostrarIndicador && i == _bolhas.length) {
                    return _bolhaDigitando(cs);
                  }
                  return _construirBolha(_bolhas[i], cs);
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
