import 'package:flutter/material.dart';

import '../models/interesse.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';
import '../services/avaliacao_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/app_snackbar.dart';

import 'chat_screen.dart';
import 'prestacoes_screen.dart';

/// Lista os interesses do doador e seu status (aguardando/aceito/recusado).
/// Quando o interesse esta ACEITO (match), libera o acesso ao chat com a ONG e
/// as prestacoes de contas.
///
/// Redesenho (Bloco 21 / Fase 4): design system + cores do TEMA (dark mode ok).
class MeusMatchesScreen extends StatefulWidget {
  const MeusMatchesScreen({super.key});

  @override
  State<MeusMatchesScreen> createState() => _MeusMatchesScreenState();
}

class _MeusMatchesScreenState extends State<MeusMatchesScreen> {
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  List<Interesse> _matches = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final usuario = await _sessionService.obterUsuario();
      if (usuario == null) {
        if (!mounted) return;
        setState(() => _carregando = false);
        return;
      }
      final lista = await _interesseService.meusMatches(usuario.id);
      if (!mounted) return;
      setState(() {
        _matches = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  // Cor e rotulo por status do interesse (cores semanticas do tema).
  (Color, String, IconData) _estilo(String status) {
    switch (status) {
      case 'ACEITO':
        return (AppColors.success, 'Aceito', Icons.check_circle);
      case 'RECUSADO':
        return (AppColors.error, 'Recusado', Icons.cancel);
      default:
        return (AppColors.warning, 'Aguardando', Icons.hourglass_top);
    }
  }

  Widget _acao(IconData icone, String texto, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 15, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(texto,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _abrirChat(Interesse i) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          interesseId: i.id,
          meuRemetente: 'DOADOR',
          titulo: i.ongNome ?? 'Conversa',
        ),
      ),
    );
  }

  void _abrirPrestacoes(Interesse i) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrestacoesScreen(
          interesseId: i.id,
          ongNome: i.ongNome ?? 'ONG',
        ),
      ),
    );
  }

  Future<void> _abrirAvaliar(Interesse i) async {
    if (i.ongId == null) return;
    final u = await _sessionService.obterUsuario();
    if (u == null || !mounted) return;

    int nota = 5;
    final comentarioC = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          title: Text('Avaliar ${i.ongNome ?? "ONG"}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  return IconButton(
                    icon: Icon(
                      idx < nota ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.ouro,
                      size: 32,
                    ),
                    onPressed: () => setStateDialog(() => nota = idx + 1),
                  );
                }),
              ),
              TextField(
                controller: comentarioC,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Comentário (opcional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await AvaliacaoService().avaliar(
                    ongId: i.ongId!,
                    doadorId: u.id,
                    nota: nota,
                    comentario: comentarioC.text.trim(),
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  if (!mounted) return;
                  AppSnackbar.sucesso(context, 'Avaliação enviada! Obrigado 💚');
                } catch (e) {
                  if (!mounted) return;
                  AppSnackbar.erro(
                      context, e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );

    // Descarta o controller apos o dialogo fechar (evita vazamento).
    comentarioC.dispose();
  }

  Widget _card(Interesse i) {
    final cs = Theme.of(context).colorScheme;
    final (cor, rotulo, icone) = _estilo(i.status);
    final aceito = i.status == 'ACEITO';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: aceito ? () => _abrirChat(i) : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: cor.withValues(alpha: 0.12),
                  child: Icon(icone, color: cor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.necessidadeTitulo ?? 'Necessidade',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i.ongNome ?? 'ONG',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      if (aceito) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: 6,
                          children: [
                            _acao(Icons.chat_bubble_outline, 'Conversar',
                                () => _abrirChat(i)),
                            _acao(Icons.receipt_long, 'Prestação',
                                () => _abrirPrestacoes(i)),
                            _acao(Icons.star_outline, 'Avaliar',
                                () => _abrirAvaliar(i)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _badgeStatus(cor, rotulo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgeStatus(Color cor, String rotulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: AppRadius.brSm,
      ),
      child: Text(
        rotulo,
        style: TextStyle(
            color: cor, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _vazio() {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.handshake_outlined, size: 56, color: cs.outline),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Você ainda não tem matches.\nVá ao Explorar e encontre uma causa para apoiar!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Matches'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        color: AppColors.primary,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _matches.isEmpty
                ? _vazio()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _matches.length,
                    itemBuilder: (context, i) => _card(_matches[i]),
                  ),
      ),
    );
  }
}
