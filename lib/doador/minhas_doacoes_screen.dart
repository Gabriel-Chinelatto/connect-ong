import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../doacao.dart';
import '../models/doacao_financeira.dart';
import '../models/interesse.dart';
import '../services/doacao_financeira_service.dart';
import '../services/doacao_service.dart';
import '../services/interesse_service.dart';
import '../services/relatorio_pdf_service.dart';
import '../services/session_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/doacao_card.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/loading_widget.dart';

import 'cadastrar_doacao_screen.dart';
import '../widgets/common/app_footer.dart';

/// Historico de doacoes REAIS do doador logado:
///  - Doacoes financeiras via PIX (GET /doacoes-financeiras?doadorId=),
///    com ONG, valor e data;
///  - Itens doados = matches ACEITOS (GET /interesses?doadorId=);
///  - Ofertas de itens cadastradas pelo doador (GET /doacoes/minhas),
///    com editar/excluir e o botao "Nova Doacao".
///
/// O botao "Exportar PDF" gera o relatorio com esses dados reais
/// (valor, ONG e data) via [RelatorioPdfService].
class MinhasDoacoesScreen extends StatefulWidget {
  const MinhasDoacoesScreen({super.key});

  @override
  State<MinhasDoacoesScreen> createState() => _MinhasDoacoesScreenState();
}

class _MinhasDoacoesScreenState extends State<MinhasDoacoesScreen> {
  final DoacaoService _ofertaService = DoacaoService();
  final DoacaoFinanceiraService _pixService = DoacaoFinanceiraService();
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  bool carregando = true;
  bool _exportando = false; // guarda anti-duplo-toque do PDF

  String? _nomeDoador;
  List<DoacaoFinanceira> _doacoesPix = [];
  List<Interesse> _itensDoados = []; // matches ACEITOS
  List<Doacao> ofertas = [];

  @override
  void initState() {
    super.initState();
    carregarDoacoes();
  }

  Future<void> carregarDoacoes() async {
    setState(() => carregando = true);

    bool houveFalha = false;
    try {
      final usuario = await _sessionService.obterUsuario();
      _nomeDoador = usuario?.nome;

      // As tres fontes sao independentes: uma falha nao derruba as outras.
      final futuros = await Future.wait<Object?>([
        usuario == null
            ? Future.value(<DoacaoFinanceira>[])
            : _pixService.listarPorDoador(usuario.id).catchError((_) {
                houveFalha = true;
                return <DoacaoFinanceira>[];
              }),
        usuario == null
            ? Future.value(<Interesse>[])
            : _interesseService.meusMatches(usuario.id).catchError((_) {
                houveFalha = true;
                return <Interesse>[];
              }),
        _ofertaService.listarDoacoes().catchError((_) {
          houveFalha = true;
          return <Doacao>[];
        }),
      ]);

      if (!mounted) return;
      setState(() {
        _doacoesPix = futuros[0] as List<DoacaoFinanceira>;
        _itensDoados = (futuros[1] as List<Interesse>)
            .where((m) => m.status == 'ACEITO')
            .toList();
        ofertas = futuros[2] as List<Doacao>;
      });

      if (houveFalha) {
        AppSnackbar.erro(
          context,
          'Parte das doações não pôde ser carregada. Verifique a conexão.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(
        context,
        'Não foi possível carregar as doações. Verifique a conexão com a API.',
      );
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> abrirFormulario([Doacao? doacao]) async {
    final atualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CadastrarDoacaoScreen(doacao: doacao),
      ),
    );

    if (atualizado == true) {
      carregarDoacoes();
    }
  }

  Future<void> excluirOferta(Doacao doacao) async {
    final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Excluir doação'),
              content: Text('Deseja excluir "${doacao.nome}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmar) return;

    try {
      await _ofertaService.excluirDoacao(doacao.id!);

      if (!mounted) return;
      AppSnackbar.sucesso(context, 'Doação excluída com sucesso.');
      carregarDoacoes();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, 'Erro ao excluir doação.');
    }
  }

  bool get _temDoacoesReais => _doacoesPix.isNotEmpty || _itensDoados.isNotEmpty;

  double get _totalPix =>
      _doacoesPix.fold<double>(0, (soma, d) => soma + d.valor);

  String get _totalPixFormatado =>
      'R\$ ${_totalPix.toStringAsFixed(2).replaceAll('.', ',')}';

  // Exporta o PDF com as doacoes REAIS (PIX com valor/ONG/data + itens doados).
  Future<void> exportarPdf() async {
    if (!_temDoacoesReais || _exportando) return;

    setState(() => _exportando = true);
    try {
      final bytes = await RelatorioPdfService.historicoDoacoes(
        doacoesPix: _doacoesPix,
        itensDoados: _itensDoados,
        nomeDoador: _nomeDoador,
      );

      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, 'Não foi possível gerar o PDF.');
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Doações'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exportar PDF',
            onPressed: _temDoacoesReais && !_exportando ? exportarPdf : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nova Doação',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => abrirFormulario(),
      ),
      body: carregando
          ? const LoadingWidget(mensagem: 'Carregando doações...')
          : RefreshIndicator(
              onRefresh: carregarDoacoes,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _cabecalhoResumo(),
                  const SizedBox(height: AppSpacing.lg),

                  // ----- Doacoes financeiras via PIX -----
                  _tituloSecao(Icons.pix, 'Doações via PIX'),
                  const SizedBox(height: AppSpacing.sm),
                  if (_doacoesPix.isEmpty)
                    _vazioSecao(
                        'Você ainda não fez doações via PIX. Elas aparecem '
                        'aqui com ONG, valor e data.')
                  else
                    ..._doacoesPix.map(_cardPix),

                  const SizedBox(height: AppSpacing.lg),

                  // ----- Itens doados (matches aceitos) -----
                  _tituloSecao(Icons.handshake_outlined,
                      'Itens doados (matches aceitos)'),
                  const SizedBox(height: AppSpacing.sm),
                  if (_itensDoados.isEmpty)
                    _vazioSecao(
                        'Quando uma ONG aceitar seu interesse em doar um item, '
                        'a doação aparece aqui.')
                  else
                    ..._itensDoados.map(_cardItemDoado),

                  const SizedBox(height: AppSpacing.lg),

                  // ----- Ofertas de itens cadastradas (CRUD) -----
                  _tituloSecao(Icons.inventory_2_outlined,
                      'Itens que você ofereceu (${ofertas.length})'),
                  const SizedBox(height: AppSpacing.sm),
                  if (ofertas.isEmpty)
                    _vazioSecao(
                        'Nenhum item cadastrado. Toque em "Nova Doação" para '
                        'oferecer um item.')
                  else
                    ...ofertas.map(
                      (doacao) => DoacaoCard(
                        doacao: doacao,
                        onEditar: () => abrirFormulario(doacao),
                        onExcluir: () => excluirOferta(doacao),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),
                  const AppFooter(),
                ],
              ),
            ),
    );
  }

  // ---- Cabecalho com o resumo das doacoes reais ----
  Widget _cabecalhoResumo() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: AppRadius.brXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suas doações',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _chipResumo(Icons.pix, '$_totalPixFormatado doados via PIX'),
              _chipResumo(
                  Icons.handshake_outlined,
                  _itensDoados.length == 1
                      ? '1 item doado'
                      : '${_itensDoados.length} itens doados'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipResumo(IconData icone, String texto) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(IconData icone, String titulo) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icone, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            titulo,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // Cartao de uma doacao PIX: ONG + data + valor em destaque.
  Widget _cardPix(DoacaoFinanceira d) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.pix, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.ongNome,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.dataFormatada,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            d.valorFormatado,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Cartao de um item doado (match ACEITO): item + ONG.
  Widget _cardItemDoado(Interesse m) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            child:
                const Icon(Icons.volunteer_activism, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.necessidadeTitulo ?? 'Item doado',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Para ${m.ongNome ?? 'ONG'}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: AppRadius.brSm,
            ),
            child: const Text(
              'ACEITO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Aviso curto de secao vazia (mantem a tela leve, sem tres EmptyStates).
  Widget _vazioSecao(String texto) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: AppRadius.brLg,
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
      ),
    );
  }
}
