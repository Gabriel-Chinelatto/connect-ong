import 'package:flutter/material.dart';

import '../models/interesse.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';
import '../services/avaliacao_service.dart';
import 'chat_screen.dart';
import 'prestacoes_screen.dart';

class MeusMatchesScreen extends StatefulWidget {
  const MeusMatchesScreen({super.key});

  @override
  State<MeusMatchesScreen> createState() => _MeusMatchesScreenState();
}

class _MeusMatchesScreenState extends State<MeusMatchesScreen> {
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  static const Color _verde = Color(0xFF0A8449);

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

  // Cor e rotulo por status do interesse.
  (Color, String, IconData) _estilo(String status) {
    switch (status) {
      case 'ACEITO':
        return (_verde, 'Aceito', Icons.check_circle);
      case 'RECUSADO':
        return (Colors.red.shade600, 'Recusado', Icons.cancel);
      default:
        return (Colors.orange.shade700, 'Aguardando', Icons.hourglass_top);
    }
  }

  Widget _acao(IconData icone, String texto, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: _verde),
          const SizedBox(width: 4),
          Text(texto,
              style: const TextStyle(
                  color: _verde, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
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
                      idx < nota ? Icons.star : Icons.star_border,
                      color: Colors.amber,
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
            ElevatedButton(
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Avaliação enviada! Obrigado 💚'),
                      backgroundColor: _verde,
                    ),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content:
                          Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
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
    final (cor, rotulo, icone) = _estilo(i.status);
    final aceito = i.status == 'ACEITO';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: aceito
            ? () {
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
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cor.withValues(alpha: 0.12),
                child: Icon(icone, color: cor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.necessidadeTitulo ?? 'Necessidade',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i.ongNome ?? 'ONG',
                      style: const TextStyle(color: _verde),
                    ),
                    if (aceito) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _acao(Icons.chat_bubble_outline, 'Conversar',
                              () => _abrirChat(i)),
                          _acao(Icons.receipt_long, 'Prestação',
                              () => _abrirPrestacoes(i)),
                          _acao(Icons.star_outline, 'Avaliar ONG',
                              () => _abrirAvaliar(i)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rotulo,
                  style: TextStyle(color: cor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Matches'),
        backgroundColor: _verde,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _matches.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Você ainda não demonstrou interesse em nenhuma necessidade.\nVá ao feed e encontre uma causa!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _matches.length,
                    itemBuilder: (context, i) => _card(_matches[i]),
                  ),
      ),
    );
  }
}
