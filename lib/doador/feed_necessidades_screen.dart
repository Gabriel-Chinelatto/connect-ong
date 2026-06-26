import 'package:flutter/material.dart';

import '../models/necessidade.dart';
import '../services/necessidade_service.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';
import '../services/perfil_service.dart';

/// Feed das necessidades abertas das ONGs, com filtros (busca, categoria,
/// urgentes) e priorizacao pela cidade do doador. Hero feature: ao demonstrar
/// interesse numa necessidade, cria um interesse que a ONG pode aceitar (match),
/// habilitando o chat.
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

  String _busca = '';
  String? _categoria; // null = todas
  bool _soUrgentes = false;
  String _minhaCidade = '';

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
      String cidade = '';
      if (usuario != null) {
        try {
          final perfil = await PerfilService().obter(usuario.id);
          cidade = (perfil['cidade'] ?? '').toString();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _doadorId = usuario?.id;
        _necessidades = lista;
        _minhaCidade = cidade;
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

  List<String> get _categorias {
    final set = _necessidades
        .map((n) => n.categoria)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  List<Necessidade> get _filtradas {
    final q = _busca.toLowerCase().trim();
    final cidade = _minhaCidade.toLowerCase().trim();

    final lista = _necessidades.where((n) {
      final bateBusca = q.isEmpty ||
          n.titulo.toLowerCase().contains(q) ||
          (n.ongNome ?? '').toLowerCase().contains(q) ||
          n.categoria.toLowerCase().contains(q);
      final bateCategoria = _categoria == null || n.categoria == _categoria;
      final bateUrgente = !_soUrgentes || n.urgente;
      return bateBusca && bateCategoria && bateUrgente;
    }).toList();

    // Ordenacao inteligente: urgentes primeiro, depois ONGs da mesma cidade.
    int score(Necessidade n) {
      int s = 0;
      if (n.urgente) s += 2;
      if (cidade.isNotEmpty &&
          (n.ongCidade ?? '').toLowerCase().trim() == cidade) {
        s += 1;
      }
      return s;
    }

    lista.sort((a, b) => score(b).compareTo(score(a)));
    return lista;
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
                Flexible(
                  child: Text(
                    n.ongNome ?? 'ONG',
                    style: const TextStyle(
                        color: _verde, fontWeight: FontWeight.w600),
                  ),
                ),
                if (n.ongVerificada) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 16, color: Colors.blue),
                ],
              ],
            ),
            if (n.ongTotalAvaliacoes > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    '${n.ongNotaMedia} (${n.ongTotalAvaliacoes})',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
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

  Widget _vazio(String msg) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _barraFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _busca = v),
            decoration: InputDecoration(
              hintText: 'Buscar por título, ONG ou categoria...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('Urgentes'),
                  selected: _soUrgentes,
                  selectedColor: Colors.red.shade100,
                  onSelected: (v) => setState(() => _soUrgentes = v),
                ),
                const SizedBox(width: 8),
                ..._categorias.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c),
                      selected: _categoria == c,
                      selectedColor: _verde.withValues(alpha: 0.2),
                      onSelected: (v) =>
                          setState(() => _categoria = v ? c : null),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Necessidades das ONGs'),
        backgroundColor: _verde,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (!_carregando && _necessidades.isNotEmpty) _barraFiltros(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _necessidades.isEmpty
                      ? _vazio('Nenhuma necessidade aberta no momento.')
                      : filtradas.isEmpty
                          ? _vazio('Nenhuma necessidade com esse filtro.')
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtradas.length,
                              itemBuilder: (context, i) => _card(filtradas[i]),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
