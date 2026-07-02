import 'package:flutter/material.dart';

import '../doador/notificacoes_screen.dart';
import '../services/notificacao_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';

/// Sino de notificacoes com contador de nao-lidas.
///
/// Sem [cor] explicita, usa a cor de conteudo do TEMA (funciona no claro e no
/// escuro). Passe [cor] apenas quando o sino estiver sobre um fundo especial
/// (ex.: gradiente verde).
class NotificacaoBell extends StatefulWidget {
  final Color? cor;

  const NotificacaoBell({super.key, this.cor});

  @override
  State<NotificacaoBell> createState() => _NotificacaoBellState();
}

class _NotificacaoBellState extends State<NotificacaoBell> {
  final NotificacaoService _service = NotificacaoService();
  final SessionService _sessionService = SessionService();

  int _naoLidas = 0;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  Future<void> _atualizar() async {
    final u = await _sessionService.obterUsuario();
    if (u == null) return;
    try {
      final n = await _service.contarNaoLidas(u.id);
      if (mounted) setState(() => _naoLidas = n);
    } catch (_) {}
  }

  Future<void> _abrir() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
    );
    _atualizar(); // recarrega o contador ao voltar
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notificações',
          icon: Icon(
            Icons.notifications_outlined,
            color: widget.cor ?? Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: _abrir,
        ),
        if (_naoLidas > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _naoLidas > 9 ? '9+' : '$_naoLidas',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
