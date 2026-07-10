import 'package:flutter/material.dart';

import '../models/notificacao.dart';
import '../theme/app_colors.dart';

/// Toast in-app de notificação: um card que desliza do topo por alguns segundos
/// (como uma notificação de celular), colorido conforme o TIPO. Aparece quando o
/// app detecta uma nova notificação sem que o usuário precise abrir o sino.

/// Cor + ícone por categoria da notificação. Distingue aceite/recusa pelo título
/// (o backend usa o mesmo tipo "MATCH" para os dois).
({Color cor, IconData icone}) estiloDaNotificacao(Notificacao n) {
  final t = n.titulo.toLowerCase();
  final tipo = n.tipo.toUpperCase();

  if (t.contains('recus')) {
    return (cor: AppColors.error, icone: Icons.cancel);
  }
  if (t.contains('aceit')) {
    return (cor: AppColors.success, icone: Icons.check_circle);
  }
  if (t.contains('avali')) {
    return (cor: Colors.amber.shade800, icone: Icons.star);
  }
  if (t.contains('recebida') || t.contains('doação')) {
    return (cor: AppColors.success, icone: Icons.volunteer_activism);
  }
  switch (tipo) {
    case 'MENSAGEM':
      return (cor: Colors.blue.shade600, icone: Icons.chat_bubble);
    case 'PRESTACAO':
      return (cor: Colors.teal.shade600, icone: Icons.receipt_long);
    case 'CAMPANHA':
      return (cor: Colors.deepOrange.shade400, icone: Icons.campaign);
    case 'NECESSIDADE':
    case 'FAVORITO':
      return (cor: Colors.indigo.shade400, icone: Icons.favorite);
    default:
      return (cor: AppColors.primary, icone: Icons.notifications);
  }
}

// Fila simples: mostra um toast por vez (evita sobreposição quando chegam
// várias notificações juntas).
final List<_Pedido> _fila = [];
bool _mostrando = false;

class _Pedido {
  final Notificacao notificacao;
  final VoidCallback? onTap;
  _Pedido(this.notificacao, this.onTap);
}

void mostrarNotificacaoToast(BuildContext context, Notificacao n,
    {VoidCallback? onTap}) {
  _fila.add(_Pedido(n, onTap));
  _bombear(context);
}

void _bombear(BuildContext context) {
  if (_mostrando || _fila.isEmpty) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _mostrando = true;
  final pedido = _fila.removeAt(0);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastCard(
      notificacao: pedido.notificacao,
      onTap: pedido.onTap,
      onClose: () {
        entry.remove();
        _mostrando = false;
        _bombear(context); // mostra o próximo da fila, se houver
      },
    ),
  );
  overlay.insert(entry);
}

class _ToastCard extends StatefulWidget {
  final Notificacao notificacao;
  final VoidCallback? onTap;
  final VoidCallback onClose;

  const _ToastCard({
    required this.notificacao,
    required this.onClose,
    this.onTap,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  bool _fechando = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    // Fica visível ~4s e some sozinho.
    Future.delayed(const Duration(milliseconds: 4200), _fechar);
  }

  Future<void> _fechar() async {
    if (_fechando) return;
    _fechando = true;
    if (mounted) await _ctrl.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notificacao;
    final estilo = estiloDaNotificacao(n);
    final media = MediaQuery.of(context);

    return Positioned(
      top: media.padding.top + 10,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    widget.onTap?.call();
                    _fechar();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                          left: BorderSide(color: estilo.cor, width: 5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: estilo.cor.withValues(alpha: 0.15),
                          child: Icon(estilo.icone, color: estilo.cor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                n.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.mensagem,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dispensar',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _fechar,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
