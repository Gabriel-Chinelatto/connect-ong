import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/mensagem.dart';
import '../services/mensagem_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/tempo.dart';
import '../widgets/common/visualizador_imagem.dart';
import '../widgets/feedback/app_snackbar.dart';
import 'perfil_publico_ong_screen.dart';

/// Mapa CODIGO -> emoji das reacoes. O backend guarda o codigo (ex.: 'LIKE'),
/// e a UI mostra o caractere correspondente.
const Map<String, String> _emojiReacoes = {
  'LIKE': '👍',
  'LOVE': '❤️',
  'LAUGH': '😂',
  'WOW': '😮',
  'SAD': '😢',
  'PRAY': '🙏',
};

/// Ordem fixa dos codigos exibidos no seletor de reacao.
const List<String> _codigosReacoes = [
  'LIKE',
  'LOVE',
  'LAUGH',
  'WOW',
  'SAD',
  'PRAY',
];

/// Tela de chat de um match. Atualiza automaticamente a cada 2 segundos
/// (polling) — confiavel e funciona em qualquer plataforma.
///
/// Redesenho (Bloco 21 / Fase 4): design system + cores do TEMA (dark mode ok).
class ChatScreen extends StatefulWidget {
  final int interesseId;
  final String meuRemetente; // 'DOADOR' neste app
  final String titulo;

  /// Dados OPCIONAIS da ONG do match (podem faltar em chamadores antigos —
  /// tudo degrada graciosamente): quando presentes, o cabeçalho estilo
  /// WhatsApp fica tocável e navega para o perfil público da ONG.
  final int? ongId;
  final String? ongNome;

  /// true quando o match veio com `bloqueadoPelaOng` (a ONG bloqueou o
  /// doador): a tela já abre com o envio desabilitado e o aviso inline.
  final bool bloqueadoPelaOng;

  const ChatScreen({
    super.key,
    required this.interesseId,
    required this.meuRemetente,
    required this.titulo,
    this.ongId,
    this.ongNome,
    this.bloqueadoPelaOng = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MensagemService _service = MensagemService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<Mensagem> _mensagens = [];
  bool _carregando = true;
  bool _enviando = false;
  Timer? _timer;

  // Anexo de imagem PENDENTE (escolhido, ainda nao enviado) + guard do picker.
  Uint8List? _anexoBytes;
  String? _anexoBase64;
  bool _abrindoGaleria = false;

  // Cache dos anexos recebidos ja decodificados (por id da mensagem) — o
  // polling de 2s reconstroi a lista o tempo todo; sem cache, cada rebuild
  // decodificaria base64 de novo.
  final Map<int, Uint8List> _cacheAnexos = {};

  // Presenca do OUTRO participante (best-effort, sem spinner/erro). Usa os
  // campos NOVOS do backend: `online` calculado no servidor e
  // `ultimoVistoEpoch` em millis UTC (a prova de fuso).
  bool _online = false;
  int? _ultimoVistoEpoch;
  bool _digitando = false;

  // Throttle do heartbeat de digitacao: no maximo 1 envio a cada 2s.
  DateTime? _ultimoHeartbeat;

  // Envio bloqueado pela ONG: inicia pelo match (bloqueadoPelaOng) e tambem
  // vira true se um POST /mensagens voltar 403 (BloqueadoException). Sem loop
  // de reenvio: a mensagem que falhou fica no campo, agora desabilitado.
  bool _bloqueado = false;

  @override
  void initState() {
    super.initState();
    _bloqueado = widget.bloqueadoPelaOng;
    _carregar(primeira: true);
    _carregarStatus();
    // Polling: busca novas mensagens a cada 2 segundos.
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _carregar();
      _carregarStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _carregar({bool primeira = false}) async {
    try {
      final lista = await _service.listar(widget.interesseId);
      if (!mounted) return;
      final mudou = lista.length != _mensagens.length;
      setState(() {
        _mensagens = lista;
        _carregando = false;
      });
      if (mudou) _irParaOFim();
    } catch (e) {
      if (!mounted) return;
      if (primeira) setState(() => _carregando = false);
    }
  }

  // Presenca do outro participante. Best-effort: o service ja devolve default
  // seguro, entao aqui nao ha spinner nem estado de erro.
  Future<void> _carregarStatus() async {
    final status = await _service.status(widget.interesseId);
    if (!mounted) return;
    setState(() {
      _online = (status['online'] ?? false) as bool;
      _ultimoVistoEpoch = (status['ultimoVistoEpoch'] as num?)?.toInt();
      _digitando = (status['digitando'] ?? false) as bool;
    });
  }

  // Heartbeat de digitacao (best-effort) com throttle de 2s: so avisa o
  // backend enquanto ha texto e no maximo 1 vez a cada 2 segundos.
  void _aoDigitar(String texto) {
    if (texto.trim().isEmpty) return;
    final agora = DateTime.now();
    if (_ultimoHeartbeat != null &&
        agora.difference(_ultimoHeartbeat!) < const Duration(seconds: 2)) {
      return;
    }
    _ultimoHeartbeat = agora;
    _service.digitando(widget.interesseId);
  }

  void _irParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    final anexo = _anexoBase64;
    // Pode enviar SO texto, SO imagem, ou os dois — mas nunca nada.
    if (texto.isEmpty && (anexo == null || anexo.isEmpty)) return;
    if (_enviando) return; // guard anti-duplo-toque
    setState(() => _enviando = true);
    try {
      await _service.enviar(
        interesseId: widget.interesseId,
        remetente: widget.meuRemetente,
        conteudo: texto,
        anexoBase64: anexo,
      );
      _controller.clear();
      if (mounted) {
        setState(() {
          _anexoBytes = null;
          _anexoBase64 = null;
        });
      }
      await _carregar();
    } on BloqueadoException {
      // 403: a ONG bloqueou este doador. Desabilita o envio com o aviso
      // inline — sem snackbar de erro e sem reenviar a mensagem que falhou.
      if (mounted) setState(() => _bloqueado = true);
    } catch (e) {
      if (mounted) {
        AppSnackbar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // Escolhe uma imagem da galeria para anexar (com resize nativo 800x800
  // qualidade 80 — mesmo limite da foto de perfil, garante < 2MB).
  Future<void> _escolherAnexo() async {
    if (_abrindoGaleria) return; // anti-duplo-toque
    _abrindoGaleria = true;
    try {
      final XFile? img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
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
        AppSnackbar.erro(context, 'Não foi possível abrir a galeria.');
      }
    } finally {
      _abrindoGaleria = false;
    }
  }

  // Bytes do anexo de uma mensagem recebida/enviada (decodifica 1x e cacheia).
  Uint8List? _bytesDoAnexo(Mensagem m) {
    if (!m.temImagem) return null;
    final emCache = _cacheAnexos[m.id];
    if (emCache != null) return emCache;
    try {
      final bytes = base64Decode(m.anexoBase64!);
      _cacheAnexos[m.id] = bytes;
      return bytes;
    } catch (_) {
      return null; // base64 corrompido: mostra so o texto
    }
  }

  // Abre o seletor de reacao (bottom sheet) para uma mensagem. Ao tocar num
  // emoji, fecha o sheet e envia a reacao.
  void _abrirSeletorReacao(Mensagem m) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final codigo in _codigosReacoes)
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      _reagir(m, codigo);
                    },
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        _emojiReacoes[codigo] ?? '',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Envia a reacao (toggle no backend) e recarrega para refletir o estado.
  Future<void> _reagir(Mensagem m, String codigo) async {
    try {
      await _service.reagir(m.id, codigo);
      await _carregar();
    } catch (e) {
      if (mounted) {
        AppSnackbar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  // Texto de presenca exibido abaixo do nome na AppBar (4 faixas: online /
  // hoje / ontem / mais antigo — ver utils/tempo.dart). String vazia quando
  // nao ha nada relevante a mostrar.
  String _textoPresenca() {
    return textoVistoPorUltimo(
      online: _online,
      ultimoVisto: dataLocalDeEpoch(_ultimoVistoEpoch),
    );
  }

  Widget _bolha(Mensagem m) {
    final cs = Theme.of(context).colorScheme;
    final minha = m.remetente == widget.meuRemetente;
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onLongPress: () => _abrirSeletorReacao(m),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              margin: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: AppSpacing.md,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: minha ? AppColors.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(minha ? 16 : 4),
                  bottomRight: Radius.circular(minha ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Anexo de imagem (arredondado, ~60% da largura da tela,
                  // tap → tela cheia).
                  if (_bytesDoAnexo(m) != null) ...[
                    GestureDetector(
                      onTap:
                          () => VisualizadorImagem.abrir(
                            context,
                            _bytesDoAnexo(m)!,
                          ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6,
                            maxHeight: 260,
                          ),
                          child: Image.memory(
                            _bytesDoAnexo(m)!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                    if (m.conteudo.isNotEmpty) const SizedBox(height: 6),
                  ],
                  if (m.conteudo.isNotEmpty)
                    Text(
                      m.conteudo,
                      style: TextStyle(
                        color: minha ? Colors.white : cs.onSurface,
                        height: 1.3,
                      ),
                    ),
                  // Check de "visto" apenas nas MINHAS mensagens.
                  if (minha)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          m.lida ? Icons.done_all : Icons.check,
                          size: 14,
                          color:
                              m.lida ? Colors.lightBlueAccent : Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Chip com as reacoes (emojis), quando houver.
          if (m.reacoes.isNotEmpty) _chipReacoes(m),
        ],
      ),
    );
  }

  // Pequeno "chip" com os emojis das reacoes da mensagem. Destaca sutilmente
  // quando ha uma reacao do MEU lado.
  Widget _chipReacoes(Mensagem m) {
    final cs = Theme.of(context).colorScheme;
    final euReagi = m.reacoes.any((r) => r.lado == widget.meuRemetente);
    final texto = m.reacoes.map((r) => _emojiReacoes[r.emoji] ?? '').join();
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: 2,
        bottom: 2,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color:
              euReagi
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border:
              euReagi
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
                  : null,
        ),
        child: Text(texto, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  // Abre o perfil público da ONG do match (cabeçalho estilo WhatsApp).
  void _abrirPerfilOng() {
    final ongId = widget.ongId;
    if (ongId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PerfilPublicoOngScreen(
              ongId: ongId,
              ongNome: widget.ongNome ?? widget.titulo,
            ),
      ),
    );
  }

  // Cabeçalho estilo WhatsApp: avatar à esquerda + coluna nome (negrito) e
  // status (fonte menor). Tocável quando o chamador informou a ONG.
  Widget _cabecalhoAppBar(ColorScheme cs) {
    // Nome exibido: ONG quando conhecida; senão o título do match (assunto).
    final nome =
        (widget.ongNome ?? '').trim().isNotEmpty
            ? widget.ongNome!.trim()
            : widget.titulo;
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    final conteudo = Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            inicial,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              if (_digitando)
                Text(
                  'digitando...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                  ),
                )
              else if (_textoPresenca().isNotEmpty)
                Text(
                  _textoPresenca(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ],
    );

    // Sem ongId (chamador antigo), o cabeçalho fica como antes (não tocável).
    if (widget.ongId == null) return conteudo;

    return Tooltip(
      message: 'Ver perfil da ONG',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _abrirPerfilOng,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: conteudo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: _cabecalhoAppBar(cs)),
      body: Column(
        children: [
          Expanded(
            child:
                _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _mensagens.isEmpty
                    ? Center(
                      child: Text(
                        'Nenhuma mensagem ainda.\nDiga olá! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    )
                    : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      itemCount: _mensagens.length,
                      itemBuilder: (context, i) => _bolha(_mensagens[i]),
                    ),
          ),
          // Preview do anexo pendente (escolhido e ainda nao enviado), com
          // botao para remover antes de enviar. Oculto quando bloqueado.
          if (_anexoBytes != null && !_bloqueado)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.brMd,
                    child: Image.memory(
                      _anexoBytes!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      tooltip: 'Remover anexo',
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                      icon: Icon(Icons.close, size: 16, color: cs.onSurface),
                      onPressed:
                          _enviando
                              ? null
                              : () => setState(() {
                                _anexoBytes = null;
                                _anexoBase64 = null;
                              }),
                    ),
                  ),
                ],
              ),
            ),
          // Bloqueado pela ONG: no lugar do campo de envio, aviso inline —
          // nada de retry; o doador continua vendo o histórico da conversa.
          if (_bloqueado)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: AppRadius.brMd,
                ),
                child: Row(
                  children: [
                    Icon(Icons.block, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Você não pode enviar mensagens para esta ONG',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Anexar imagem',
                      onPressed: _enviando ? null : _escolherAnexo,
                      icon: Icon(
                        Icons.image_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Mensagem...',
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
                        onChanged: _aoDigitar,
                        onSubmitted: (_) => _enviar(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        tooltip: 'Enviar mensagem',
                        icon:
                            _enviando
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.send, color: Colors.white),
                        onPressed: _enviando ? null : _enviar,
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
}
