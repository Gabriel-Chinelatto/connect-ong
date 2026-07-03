import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/campanha.dart';
import '../services/api_service.dart';
import '../services/doacao_financeira_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/celebracao.dart';

/// Fluxo de doação PIX simulado (realista), usado tanto para doar direto a uma
/// ONG quanto para CONTRIBUIR com uma campanha ([campanha] != null):
///
/// 1. Escolher o valor (atalhos + campo livre "Outro valor");
/// 2. "Gerar código PIX" → POST /doacoes-financeiras/gerar-codigo → código
///    copia-e-cola com botão copiar;
/// 3. Automaticamente entra em "Aguardando pagamento..." (ícone pulsando) com
///    o botão "Simular pagamento concluído" (demonstração, sem cobrança real);
/// 4. POST /doacoes-financeiras registra a doação → comprovante com animação
///    festiva (checkmark + confete).
///
/// Retorna `true` no pop quando a doação foi concluída (para a tela chamadora
/// recarregar, ex.: progresso da campanha).
class DoarPixScreen extends StatefulWidget {
  final int? ongId;
  final String ongNome;

  /// Quando presente, a doação é uma contribuição para esta campanha
  /// (envia campanhaId no registro e mostra o título no comprovante).
  final Campanha? campanha;

  const DoarPixScreen({
    super.key,
    required this.ongId,
    required this.ongNome,
    this.campanha,
  });

  @override
  State<DoarPixScreen> createState() => _DoarPixScreenState();
}

enum _Etapa { valor, aguardando, sucesso }

class _DoarPixScreenState extends State<DoarPixScreen>
    with SingleTickerProviderStateMixin {
  final DoacaoFinanceiraService _service = DoacaoFinanceiraService();
  final SessionService _sessionService = SessionService();
  final TextEditingController _valorCtrl = TextEditingController();

  _Etapa _etapa = _Etapa.valor;
  bool _processando = false; // guarda anti-duplo-toque (gerar e confirmar)
  double _valor = 0;
  String _codigoPix = '';
  Map<String, dynamic>? _comprovante;

  // Pulso do "Aguardando pagamento..." (repete em vai-e-volta).
  late final AnimationController _pulso;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.75,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _pulso.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  // ---- Etapa 1 → 2: valida o valor e gera o código PIX ----
  Future<void> _gerarCodigo() async {
    if (_processando) return;
    final valor =
        double.tryParse(_valorCtrl.text.replaceAll(',', '.').trim()) ?? 0;
    if (valor <= 0) {
      AppSnackbar.erro(context, 'Informe um valor maior que zero.');
      return;
    }
    if (valor > 100000) {
      AppSnackbar.erro(context, 'Valor muito alto. Confira o valor digitado.');
      return;
    }
    setState(() => _processando = true);
    try {
      final codigo = await _service.gerarCodigo(valor);
      if (!mounted) return;
      setState(() {
        _valor = valor;
        _codigoPix = codigo;
        _etapa = _Etapa.aguardando;
        _processando = false;
      });
      _pulso.repeat(reverse: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processando = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  // ---- Etapa 2 → 3: "pagamento" simulado → registra a doação ----
  Future<void> _confirmarPagamento() async {
    if (_processando) return;
    setState(() => _processando = true);
    final u = await _sessionService.obterUsuario();
    if (u == null) {
      if (!mounted) return;
      setState(() => _processando = false);
      AppSnackbar.erro(context, 'Você precisa estar logado.');
      return;
    }
    if (widget.ongId == null) {
      if (!mounted) return;
      setState(() => _processando = false);
      AppSnackbar.erro(context, 'ONG não identificada. Tente novamente.');
      return;
    }
    try {
      final resp = await _service.doar(
        ongId: widget.ongId!,
        doadorId: u.id,
        valor: _valor,
        codigoPix: _codigoPix,
        campanhaId: widget.campanha?.id,
      );
      if (!mounted) return;
      _pulso.stop();
      setState(() {
        _comprovante = resp;
        _etapa = _Etapa.sucesso;
        _processando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _processando = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  void _copiarCodigo() {
    Clipboard.setData(ClipboardData(text: _codigoPix));
    AppSnackbar.sucesso(context, 'Código copiado!');
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.campanha != null
        ? 'Contribuir com a campanha'
        : 'Doar para ${widget.ongNome}';
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: switch (_etapa) {
              _Etapa.valor => _telaValor(),
              _Etapa.aguardando => _telaAguardando(),
              _Etapa.sucesso => _telaSucesso(),
            },
          ),
        ),
      ),
    );
  }

  // =============== ETAPA 1: escolher o valor ===============
  Widget _telaValor() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.pix, size: 56, color: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.campanha != null
              ? 'Quanto você quer contribuir com\n"${widget.campanha!.titulo}"?'
              : 'Quanto você quer doar para\n${widget.ongNome}?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (widget.campanha != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.ongNome,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [10, 25, 50, 100].map((v) {
            final selecionado = _valorCtrl.text == '$v';
            return ChoiceChip(
              label: Text('R\$ $v'),
              selected: selecionado,
              onSelected: (_) => setState(() => _valorCtrl.text = '$v'),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _valorCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Aceita só dígitos e um separador decimal (até 2 casas).
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}[,.]?\d{0,2}')),
          ],
          onChanged: (_) => setState(() {}), // atualiza o chip selecionado
          decoration: const InputDecoration(
            labelText: 'Outro valor (R\$)',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _processando ? null : _gerarCodigo,
            icon: _processando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.qr_code_2),
            label: const Text('Gerar código PIX'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Doação simulada para fins de demonstração (sem cobrança real).',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  // =============== ETAPA 2: código gerado + aguardando pagamento ===============
  Widget _telaAguardando() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pague R\$ ${_valor.toStringAsFixed(2).replaceAll('.', ',')} com o código abaixo',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Código copia-e-cola.
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código PIX (copia e cola)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                _codigoPix,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _copiarCodigo,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar código'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // "Aguardando pagamento..." pulsando.
        FadeTransition(
          opacity: _pulso,
          child: ScaleTransition(
            scale: _pulso,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.pix, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Aguardando pagamento...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _processando ? null : _confirmarPagamento,
            icon: _processando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.task_alt),
            label: const Text('Simular pagamento concluído'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Esta é uma demonstração: nenhum pagamento real é processado.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  // =============== ETAPA 3: comprovante com celebração ===============
  Widget _telaSucesso() {
    final cs = Theme.of(context).colorScheme;
    final c = _comprovante ?? const {};
    final valor = ((c['valor'] ?? _valor) as num).toDouble();
    final codigo = (c['codigoPix'] ?? _codigoPix).toString();
    final campanhaTitulo =
        (c['campanhaTitulo'] ?? widget.campanha?.titulo)?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: CelebracaoSucesso(tamanho: 150)),
        const Center(
          child: Text('Doação confirmada!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            'Obrigado por fazer a diferença 💚',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _linha('ONG', widget.ongNome),
              if (campanhaTitulo != null && campanhaTitulo.isNotEmpty)
                _linha('Campanha', campanhaTitulo),
              _linha('Valor',
                  'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}'),
              _linha('Status', 'Confirmado'),
              const SizedBox(height: AppSpacing.sm),
              Text('Código PIX (copia e cola):',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: AppRadius.brSm,
                ),
                child: Text(codigo,
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _copiarCodigo,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar código'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Concluir'),
        ),
      ],
    );
  }

  Widget _linha(String label, String valor) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(valor,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
          ),
        ],
      ),
    );
  }
}
