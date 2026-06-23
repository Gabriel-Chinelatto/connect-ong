import 'package:flutter/material.dart';

import '../models/interesse.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';

/// Painel de impacto do doador: mostra em numeros a participacao dele.
/// Calculado a partir dos interesses/matches que o app ja carrega.
class DashboardImpactoScreen extends StatefulWidget {
  const DashboardImpactoScreen({super.key});

  @override
  State<DashboardImpactoScreen> createState() =>
      _DashboardImpactoScreenState();
}

class _DashboardImpactoScreenState extends State<DashboardImpactoScreen> {
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  static const Color _verde = Color(0xFF0A8449);

  bool _carregando = true;
  String _nome = '';
  int _totalInteresses = 0;
  int _aceitos = 0;
  int _aguardando = 0;
  int _ongsApoiadas = 0;

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
      final List<Interesse> matches =
          await _interesseService.meusMatches(usuario.id);

      final aceitos = matches.where((m) => m.status == 'ACEITO').toList();
      final ongs = aceitos
          .map((m) => m.ongNome)
          .where((nome) => nome != null)
          .toSet();

      if (!mounted) return;
      setState(() {
        _nome = usuario.nome;
        _totalInteresses = matches.length;
        _aceitos = aceitos.length;
        _aguardando = matches.where((m) => m.status == 'PENDENTE').length;
        _ongsApoiadas = ongs.length;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Widget _statCard(IconData icone, String numero, String rotulo, Color cor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icone, color: cor, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            numero,
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      appBar: AppBar(
        title: const Text('Meu Impacto'),
        backgroundColor: _verde,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Olá, $_nome 👋',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Veja o impacto da sua solidariedade:',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: [
                      _statCard(Icons.handshake, '$_aceitos',
                          'Matches realizados', _verde),
                      _statCard(Icons.favorite, '$_ongsApoiadas',
                          'ONGs apoiadas', Colors.pink.shade400),
                      _statCard(Icons.send, '$_totalInteresses',
                          'Interesses enviados', Colors.blue.shade400),
                      _statCard(Icons.hourglass_top, '$_aguardando',
                          'Aguardando resposta', Colors.orange.shade600),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _verde.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.volunteer_activism, color: _verde),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _aceitos > 0
                                ? 'Obrigado por fazer a diferença! Continue conectando com causas.'
                                : 'Demonstre interesse em uma necessidade e comece a gerar impacto!',
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
