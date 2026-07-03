import 'package:flutter/material.dart';

import '../models/notificacao.dart';
import '../services/notificacao_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import 'main_shell.dart';

/// Lista as notificacoes do doador (mensagens, prestacoes, matches, etc.) e
/// permite marcar todas como lidas.
///
/// Tocar numa notificacao de PRESTACAO leva a aba Matches → Concluídas (onde
/// vive o botao "Ver prestação de contas"). DECISÃO: o payload da API
/// (NotificacaoResponseDTO) NÃO traz referência ao interesse/prestação — só
/// id, titulo, mensagem, tipo, lida e dataCriacao —, então não dá para abrir
/// a prestação exata; a aba Concluídas é o caminho mais próximo.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  final NotificacaoService _service = NotificacaoService();
  final SessionService _sessionService = SessionService();

  List<Notificacao> _itens = [];
  bool _carregando = true;
  int? _usuarioId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final u = await _sessionService.obterUsuario();
    if (u == null) {
      if (mounted) setState(() => _carregando = false);
      return;
    }
    _usuarioId = u.id;
    try {
      final lista = await _service.listar(u.id);
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _marcarTodas() async {
    if (_usuarioId == null) return;
    await _service.marcarTodas(_usuarioId!);
    _carregar();
  }

  IconData _icone(String tipo) {
    switch (tipo) {
      case 'MENSAGEM':
        return Icons.chat_bubble_outline;
      case 'PRESTACAO':
        return Icons.receipt_long;
      case 'MATCH':
        return Icons.handshake;
      default:
        return Icons.notifications;
    }
  }

  // Notificacao de PRESTACAO → aba Matches / sub-aba Concluídas. Fecha esta
  // tela (que foi empurrada por cima do shell) e pede a troca de aba pelo
  // hook global; se o shell nao estiver montado, nao faz nada.
  void _aoTocar(Notificacao n) {
    if (n.tipo != 'PRESTACAO') return;
    final irParaAba = MainShell.irParaAbaGlobal;
    if (irParaAba == null) return;
    Navigator.of(context).pop();
    irParaAba(2, 2); // aba 2 = Matches; sub-aba 2 = Concluídas
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        actions: [
          if (_itens.any((n) => !n.lida))
            TextButton(
              onPressed: _marcarTodas,
              child: const Text('Marcar todas',
                  style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        color: AppColors.primary,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _itens.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 140),
                      Center(
                        child: Text('Nenhuma notificação ainda.',
                            style: TextStyle(
                                fontSize: 16, color: cs.onSurfaceVariant)),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: _itens.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = _itens[i];
                      return Container(
                        color: n.lida
                            ? null
                            : AppColors.primary.withValues(alpha: 0.06),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: Icon(_icone(n.tipo),
                                color: AppColors.primary),
                          ),
                          title: Text(n.titulo,
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: n.lida
                                      ? FontWeight.normal
                                      : FontWeight.bold)),
                          subtitle: Text(n.mensagem,
                              style: TextStyle(color: cs.onSurfaceVariant)),
                          trailing: n.lida
                              ? null
                              : const Icon(Icons.circle,
                                  size: 10, color: AppColors.primary),
                          onTap: n.tipo == 'PRESTACAO' &&
                                  MainShell.irParaAbaGlobal != null
                              ? () => _aoTocar(n)
                              : null,
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
