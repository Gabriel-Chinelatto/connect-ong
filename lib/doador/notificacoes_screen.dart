import 'package:flutter/material.dart';

import '../models/notificacao.dart';
import '../services/notificacao_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_itens.any((n) => !n.lida))
            TextButton(
              onPressed: _marcarTodas,
              child: const Text('Marcar todas',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _itens.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 140),
                      Center(
                        child: Text('Nenhuma notificação ainda.',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey)),
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
                                  fontWeight: n.lida
                                      ? FontWeight.normal
                                      : FontWeight.bold)),
                          subtitle: Text(n.mensagem),
                          trailing: n.lida
                              ? null
                              : const Icon(Icons.circle,
                                  size: 10, color: AppColors.primary),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
