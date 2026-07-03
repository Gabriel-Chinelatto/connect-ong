import 'package:flutter/material.dart';

import '../models/interesse.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/empty_state.dart';

/// Painel de impacto do doador: mostra em numeros a participacao dele.
/// Calculado a partir dos interesses/matches que o app ja carrega.
///
/// Os cards de estatística são CLICÁVEIS e navegam para a área correspondente
/// via [onIrParaAba] (aba do shell + sub-aba dos Matches, quando aplicável).
///
/// Layout dos cards em linhas flexíveis (IntrinsicHeight), em vez de grade com
/// razão de aspecto fixa: a altura acompanha o conteúdo e não estoura com
/// fonte grande (corrige overflow real de 9.7px reportado em screenshots).
class DashboardImpactoScreen extends StatefulWidget {
  /// Navega no shell: [aba] é o índice da aba (1=Explorar, 2=Matches) e
  /// [subAbaMatches] a sub-aba dos Matches (0=Ativas, 1=Aguardando).
  final void Function(int aba, [int? subAbaMatches]) onIrParaAba;

  const DashboardImpactoScreen({super.key, required this.onIrParaAba});

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

      // ACEITO e CONCLUIDO contam como match realizado.
      final aceitos = matches
          .where((m) => m.status == 'ACEITO' || m.status == 'CONCLUIDO')
          .toList();
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

  // Card de estatística CLICÁVEL: navega para a área correspondente do app.
  Widget _statCard(IconData icone, String numero, String rotulo, Color cor,
      VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$numero $rotulo',
      child: Material(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brLg,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
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
                    Icon(Icons.chevron_right,
                        size: 20, color: cs.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
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
          ),
        ),
      ),
    );
  }

  // Linha com 2 cards de mesma altura (a do conteúdo mais alto) — cresce com
  // a fonte em vez de estourar.
  Widget _linhaStats(Widget a, Widget b) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: b),
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
                  _linhaStats(
                    _statCard(Icons.handshake, '$_aceitos',
                        'Matches realizados', AppColors.primary,
                        () => widget.onIrParaAba(2, 0)), // Matches → Ativas
                    _statCard(Icons.favorite, '$_ongsApoiadas',
                        'ONGs apoiadas', _acentoRosa,
                        () => widget.onIrParaAba(1)), // Explorar
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _linhaStats(
                    _statCard(Icons.send, '$_totalInteresses',
                        'Interesses enviados', _acentoAzul,
                        () => widget.onIrParaAba(2, 1)), // Matches → Aguardando
                    _statCard(Icons.hourglass_top, '$_aguardando',
                        'Aguardando resposta', AppColors.warning,
                        () => widget.onIrParaAba(2, 1)), // Matches → Aguardando
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
