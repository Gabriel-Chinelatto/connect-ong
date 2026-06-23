import 'package:flutter/material.dart';

import '../models/necessidade.dart';
import '../services/necessidade_service.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';

class FeedNecessidadesScreen extends StatefulWidget {
  const FeedNecessidadesScreen({super.key});

  @override
  State<FeedNecessidadesScreen> createState() => _FeedNecessidadesScreenState();
}

class _FeedNecessidadesScreenState extends State<FeedNecessidadesScreen> {
  final NecessidadeService _necessidadeService = NecessidadeService();
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  static const Color _verde = Color(0xFF0A8449);

  List<Necessidade> _necessidades = [];
  final Set<int> _jaInteressado = {}; // ids onde o doador ja clicou
  bool _carregando = true;
  int? _doadorId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final usuario = await _sessionService.obterUsuario();
      final lista = await _necessidadeService.listarAbertas();
      if (!mounted) return;
      setState(() {
        _doadorId = usuario?.id;
        _necessidades = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      _snack('Erro ao carregar necessidades', Colors.red.shade400);
    }
  }

  Future<void> _demonstrarInteresse(Necessidade n) async {
    if (_doadorId == null) {
      _snack('Você precisa estar logado como doador.', Colors.red.shade400);
      return;
    }
    try {
      await _interesseService.demonstrarInteresse(
        necessidadeId: n.id,
        doadorId: _doadorId!,
      );
      if (!mounted) return;
      setState(() => _jaInteressado.add(n.id));
      _snack('Interesse enviado! A ONG vai avaliar. 💚', _verde);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''),
          Colors.orange.shade700);
    }
  }

  void _snack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _card(Necessidade n) {
    final interessado = _jaInteressado.contains(n.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    n.titulo,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (n.urgente)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.priority_high,
                            size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 2),
                        Text('Urgente',
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.handshake, size: 16, color: _verde),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    n.ongNome ?? 'ONG',
                    style: const TextStyle(
                        color: _verde, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(n.descricao,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(n.categoria,
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 12)),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: interessado ? null : () => _demonstrarInteresse(n),
                  icon: Icon(interessado ? Icons.check : Icons.favorite,
                      size: 18),
                  label: Text(interessado ? 'Interesse enviado' : 'Tenho interesse'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Necessidades das ONGs'),
        backgroundColor: _verde,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _necessidades.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'Nenhuma necessidade aberta no momento.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _necessidades.length,
                    itemBuilder: (context, i) => _card(_necessidades[i]),
                  ),
      ),
    );
  }
}
