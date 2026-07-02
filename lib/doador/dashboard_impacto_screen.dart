import 'package:flutter/material.dart';

import '../models/interesse.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/escala.dart';
import '../widgets/feedback/empty_state.dart';

/// Painel de impacto do doador: mostra em numeros a participacao dele.
/// Calculado a partir dos interesses/matches que o app ja carrega.
///
/// Redesenho (Bloco 21 / Fase 4): design system + cores do TEMA (dark mode ok).
class DashboardImpactoScreen extends StatefulWidget {
  const DashboardImpactoScreen({super.key});

  @override
  State<DashboardImpactoScreen> createState() =>
      _DashboardImpactoScreenState();
}

class _DashboardImpactoScreenState extends State<DashboardImpactoScreen> {
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  // Acentos decorativos dos cartoes (apenas tint de icone).
  static const Color _acentoAzul = Color(0xFF2563EB);
  static const Color _acentoRosa = Color(0xFFEC4899);

  bool _carregando = true;
  bool _erro = false;
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
    setState(() {
      _carregando = true;
      _erro = false;
    });
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
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  Widget _statCard(IconData icone, String numero, String rotulo, Color cor) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icone, color: cor, size: 24),
          ),
          const Spacer(),
          Text(
            numero,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cs.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        // Aba do shell: nunca mostra seta de voltar (mesmo se houver rota
        // abaixo na pilha, como o portal na web).
        automaticallyImplyLeading: false,
        title: const Text('Meu Impacto'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? RefreshIndicator(
                  onRefresh: _carregar,
                  color: AppColors.primary,
                  child: ListView(children: [
                    const SizedBox(height: 100),
                    EmptyState(
                      icone: Icons.cloud_off_outlined,
                      mensagem: 'Não foi possível carregar',
                      detalhe: 'Verifique sua conexão e tente novamente.',
                      acaoRotulo: 'Tentar de novo',
                      onAcao: _carregar,
                    ),
                  ]),
                )
              : RefreshIndicator(
              onRefresh: _carregar,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Olá, $_nome 👋',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Veja o impacto da sua solidariedade:',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    // Cards ficam mais altos quando a fonte aumenta.
                    childAspectRatio: 1.15 / fatorFonte(context),
                    children: [
                      _statCard(Icons.handshake, '$_aceitos',
                          'Matches realizados', AppColors.primary),
                      _statCard(Icons.favorite, '$_ongsApoiadas',
                          'ONGs apoiadas', _acentoRosa),
                      _statCard(Icons.send, '$_totalInteresses',
                          'Interesses enviados', _acentoAzul),
                      _statCard(Icons.hourglass_top, '$_aguardando',
                          'Aguardando resposta', AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: AppRadius.brLg,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.volunteer_activism,
                            color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _aceitos > 0
                                ? 'Obrigado por fazer a diferença! Continue conectando com causas.'
                                : 'Demonstre interesse em uma necessidade e comece a gerar impacto!',
                            style: TextStyle(height: 1.4, color: cs.onSurface),
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
