import 'dart:async';

import 'package:flutter/material.dart';

import '../models/mensagem.dart';
import '../services/mensagem_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/app_snackbar.dart';

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

  @override
  void initState() {
    super.initState();
    _carregar(primeira: true);
    // Polling: busca novas mensagens a cada 2 segundos.
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _carregar(),
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

  Widget _bolha(Mensagem m) {
    final cs = Theme.of(context).colorScheme;
    final minha = m.remetente == widget.meuRemetente;
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
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
        child: Text(
          m.conteudo,
          style: TextStyle(
            color: minha ? Colors.white : cs.onSurface,
            height: 1.3,
          ),
        ),
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
              child: Text(
                widget.titulo,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface),
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
