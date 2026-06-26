import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/doacao_financeira_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';

/// Doacao financeira via PIX para uma ONG especifica (recebida no construtor).
/// Informa o valor, registra a doacao e exibe o comprovante retornado pela API.
class DoarPixScreen extends StatefulWidget {
  final int ongId;
  final String ongNome;

  const DoarPixScreen({
    super.key,
    required this.ongId,
    required this.ongNome,
  });

  @override
  State<DoarPixScreen> createState() => _DoarPixScreenState();
}

class _DoarPixScreenState extends State<DoarPixScreen> {
  final DoacaoFinanceiraService _service = DoacaoFinanceiraService();
  final SessionService _sessionService = SessionService();
  final TextEditingController _valor = TextEditingController();

  bool _enviando = false;
  Map<String, dynamic>? _comprovante;

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  Future<void> _doar() async {
    final valor =
        double.tryParse(_valor.text.replaceAll(',', '.').trim()) ?? 0;
    if (valor <= 0) {
      _snack('Informe um valor válido.', Colors.red);
      return;
    }
    final u = await _sessionService.obterUsuario();
    if (u == null) {
      _snack('Você precisa estar logado.', Colors.red);
      return;
    }
    setState(() => _enviando = true);
    try {
      final resp = await _service.doar(
        ongId: widget.ongId,
        doadorId: u.id,
        valor: valor,
      );
      if (!mounted) return;
      setState(() {
        _comprovante = resp;
        _enviando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _snack(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    }
  }

  void _snack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: cor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doar para ${widget.ongNome}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _comprovante == null ? _form() : _comprovanteView(),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.pix, size: 56, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(
          'Quanto você quer doar para ${widget.ongNome}?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [10, 25, 50, 100].map((v) {
            return ActionChip(
              label: Text('R\$ $v'),
              onPressed: () => setState(() => _valor.text = '$v'),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _valor,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor (R\$)',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _enviando ? null : _doar,
            icon: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.pix),
            label: const Text('Doar via PIX'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Doação simulada para fins de demonstração (sem cobrança real).',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _comprovanteView() {
    final c = _comprovante!;
    final valor = (c['valor'] ?? 0).toString();
    final codigo = (c['codigoPix'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 64, color: AppColors.primary),
        const SizedBox(height: 12),
        const Center(
          child: Text('Doação confirmada!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _linha('ONG', widget.ongNome),
                _linha('Valor', 'R\$ $valor'),
                _linha('Status', 'Confirmado'),
                const SizedBox(height: 12),
                const Text('Código PIX (copia e cola):',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(codigo,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: codigo));
                      _snack('Código copiado!', AppColors.primary);
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar código'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Concluir'),
        ),
      ],
    );
  }

  Widget _linha(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Flexible(
            child: Text(valor,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
