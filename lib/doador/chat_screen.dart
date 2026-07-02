import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mensagem.dart';
import '../services/mensagem_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/app_snackbar.dart';

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

  const ChatScreen({
    super.key,
    required this.interesseId,
    required this.meuRemetente,
    required this.titulo,
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

  // Presenca do OUTRO participante (best-effort, sem spinner/erro).
  bool _online = false;
  String? _ultimoVisto;
  bool _digitando = false;

  // Throttle do heartbeat de digitacao: no maximo 1 envio a cada 2s.
  DateTime? _ultimoHeartbeat;

  @override
  void initState() {
    super.initState();
    _carregar(primeira: true);
    _carregarStatus();
    // Polling: busca novas mensagens a cada 2 segundos.
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        _carregar();
        _carregarStatus();
      },
    );
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
      _ultimoVisto = status['ultimoVisto'] as String?;
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
    if (texto.isEmpty) return;
    setState(() => _enviando = true);
    try {
      await _service.enviar(
        interesseId: widget.interesseId,
        remetente: widget.meuRemetente,
        conteudo: texto,
      );
      _controller.clear();
      await _carregar();
    } catch (e) {
      if (mounted) {
        AppSnackbar.erro(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
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
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                          minWidth: 44, minHeight: 44),
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

  // Texto de presenca exibido abaixo do nome na AppBar. String vazia quando
  // nao ha nada relevante a mostrar.
  String _textoPresenca() {
    if (_online) return 'online';
    if (_ultimoVisto != null) {
      final dt = DateTime.parse(_ultimoVisto!).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return 'visto por último às $hh:$mm';
    }
    return '';
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
                  vertical: 4, horizontal: AppSpacing.md),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          color: m.lida
                              ? Colors.lightBlueAccent
                              : Colors.white70,
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
    final euReagi =
        m.reacoes.any((r) => r.lado == widget.meuRemetente);
    final texto =
        m.reacoes.map((r) => _emojiReacoes[r.emoji] ?? '').join();
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.md, right: AppSpacing.md, top: 2, bottom: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: euReagi
              ? AppColors.primary.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: euReagi
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(texto, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inicial =
        widget.titulo.isNotEmpty ? widget.titulo[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                inicial,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titulo,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _mensagens.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma mensagem ainda.\nDiga olá! 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        itemCount: _mensagens.length,
                        itemBuilder: (context, i) => _bolha(_mensagens[i]),
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
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
                            horizontal: 16, vertical: 12),
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
                      icon: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
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
