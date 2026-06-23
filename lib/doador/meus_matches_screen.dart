import 'package:flutter/material.dart';

import '../models/interesse.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';
import 'chat_screen.dart';

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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 14, color: _verde),
                          const SizedBox(width: 4),
                          Text('Toque para conversar',
                              style: TextStyle(
                                  color: _verde,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
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
