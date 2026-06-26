import 'package:flutter/material.dart';

import '../models/prestacao.dart';
import '../services/prestacao_service.dart';
import '../theme/app_colors.dart';

/// Exibe as prestacoes de contas de uma ONG referentes a um match (interesseId),
/// mostrando como a doacao foi aplicada, com texto e foto comprovante.
class PrestacoesScreen extends StatefulWidget {
  final int interesseId;
  final String ongNome;

  const PrestacoesScreen({
    super.key,
    required this.interesseId,
    required this.ongNome,
  });

  @override
  State<PrestacoesScreen> createState() => _PrestacoesScreenState();
}

class _PrestacoesScreenState extends State<PrestacoesScreen> {
  final PrestacaoService _service = PrestacaoService();

  List<Prestacao> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await _service.listar(widget.interesseId);
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _card(Prestacao p) {
    final temFoto = (p.fotoUrl ?? '').trim().isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (temFoto)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                p.fotoUrl!.trim(),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.titulo,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (p.descricao.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(p.descricao,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                ],
                if (p.dataCriacao != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    p.dataCriacao!.split('T').first,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prestação de contas — ${widget.ongNome}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _itens.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'A ONG ainda não publicou uma prestação de contas para esta doação.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _itens.length,
                    itemBuilder: (_, i) => _card(_itens[i]),
                  ),
      ),
    );
  }
}
