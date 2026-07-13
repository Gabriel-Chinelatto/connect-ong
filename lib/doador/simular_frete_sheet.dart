import 'package:flutter/material.dart';

import '../services/frete_service.dart';
import '../services/perfil_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../utils/categorias.dart';

/// Abre a folha (bottom sheet) de SIMULAÇÃO DE FRETE para levar uma doação até
/// a ONG [ongNome] em [destinoCidade]. Estima o custo com base na distância
/// entre a cidade do doador e a da ONG e no peso do item (a IA deduz o peso a
/// partir da descrição). São valores ESTIMADOS — não uma cotação oficial.
Future<void> mostrarSimularFrete(
  BuildContext context, {
  required String destinoCidade,
  required String ongNome,
  String? categoriaSugerida,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SimularFreteSheet(
      destinoCidade: destinoCidade,
      ongNome: ongNome,
      categoriaSugerida: categoriaSugerida,
    ),
  );
}

class _SimularFreteSheet extends StatefulWidget {
  final String destinoCidade;
  final String ongNome;
  final String? categoriaSugerida;

  const _SimularFreteSheet({
    required this.destinoCidade,
    required this.ongNome,
    this.categoriaSugerida,
  });

  @override
  State<_SimularFreteSheet> createState() => _SimularFreteSheetState();
}

class _SimularFreteSheetState extends State<_SimularFreteSheet> {
  final _itemCtrl = TextEditingController();
  final _origemCtrl = TextEditingController();

  // Categoria escolhida pelo doador (tópico) — remove a ambiguidade e melhora a
  // estimativa de peso da IA. Opcional; se null, a IA deduz pelo texto.
  String? _categoria;

  final FreteService _service = FreteService();

  // Cidade/UF do doador (origem). Buscadas do perfil; se vazias, o doador
  // digita a cidade de origem no campo _origemCtrl.
  String? _cidadeDoador;
  String? _ufDoador;
  bool _carregandoOrigem = true;

  bool _calculando = false;
  String? _erro;
  FreteEstimativa? _resultado;

  @override
  void initState() {
    super.initState();
    // Pré-seleciona a categoria sugerida (1ª necessidade da ONG), se houver.
    final sug = widget.categoriaSugerida;
    if (sug != null && sug.isNotEmpty) _categoria = Categorias.normalizar(sug);
    _carregarOrigem();
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    _origemCtrl.dispose();
    super.dispose();
  }

  // Busca a cidade/UF do doador logado para preencher a origem automaticamente.
  Future<void> _carregarOrigem() async {
    try {
      final u = await SessionService().obterUsuario();
      if (u != null) {
        final perfil = await PerfilService().obter(u.id);
        final cidade = (perfil['cidade'] ?? '').toString().trim();
        // 'estado' costuma ser a UF; toleramos ausência.
        final uf = (perfil['estado'] ?? perfil['uf'] ?? '').toString().trim();
        if (mounted) {
          setState(() {
            _cidadeDoador = cidade.isNotEmpty ? cidade : null;
            _ufDoador = uf.isNotEmpty ? uf : null;
          });
        }
      }
    } catch (_) {
      // Sem perfil: o doador digita a cidade de origem manualmente.
    } finally {
      if (mounted) setState(() => _carregandoOrigem = false);
    }
  }

  String get _origemEfetiva =>
      (_cidadeDoador ?? _origemCtrl.text).trim();

  Future<void> _calcular() async {
    FocusScope.of(context).unfocus();
    final origem = _origemEfetiva;
    if (origem.isEmpty) {
      setState(() => _erro = 'Informe a cidade de origem.');
      return;
    }
    if (_itemCtrl.text.trim().isEmpty) {
      setState(() => _erro = 'Descreva o que você quer enviar.');
      return;
    }
    setState(() {
      _calculando = true;
      _erro = null;
      _resultado = null;
    });
    try {
      final r = await _service.estimar(
        origemCidade: origem,
        origemUf: _ufDoador,
        destinoCidade: widget.destinoCidade,
        item: _itemCtrl.text.trim(),
        categoria: _categoria,
      );
      if (!mounted) return;
      setState(() => _resultado = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _calculando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Empurra o conteúdo acima do teclado quando os campos estão em foco.
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final precisaOrigem = !_carregandoOrigem && (_cidadeDoador == null);

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Simular frete',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Estime quanto custaria enviar sua doação até ${widget.ongNome} '
              '(${widget.destinoCidade}).',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),

            // Origem: automática (perfil) ou digitada quando desconhecida.
            if (_carregandoOrigem)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 3),
              )
            else if (precisaOrigem)
              TextField(
                controller: _origemCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Sua cidade (origem)',
                  prefixIcon: Icon(Icons.my_location_outlined),
                  hintText: 'Ex.: Limeira',
                ),
              )
            else
              _linhaRota(cs),
            const SizedBox(height: 12),

            TextField(
              controller: _itemCtrl,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'O que você vai enviar (com a quantidade)',
                prefixIcon: Icon(Icons.inventory_2_outlined),
                hintText: 'Ex.: 10 sacos de arroz de 1 kg',
                helperText: 'Inclua a quantidade no texto (ex.: 5 cobertores).',
              ),
            ),
            const SizedBox(height: 16),
            // Seletor de categoria (tópico): remove a ambiguidade e melhora a
            // estimativa de peso — a categoria escolhida é a que vale.
            Text(
              'Categoria',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in Categorias.todas)
                  ChoiceChip(
                    label: Text(c.rotulo),
                    avatar: Icon(
                      c.icone,
                      size: 18,
                      color: _categoria == c.valor ? Colors.white : c.cor,
                    ),
                    selected: _categoria == c.valor,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _categoria == c.valor
                          ? Colors.white
                          : cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (v) =>
                        setState(() => _categoria = v ? c.valor : null),
                  ),
              ],
            ),

            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(
                _erro!,
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _calculando ? null : _calcular,
                icon: _calculando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.calculate_outlined),
                label: Text(_calculando ? 'Calculando…' : 'Calcular frete'),
              ),
            ),

            if (_resultado != null) ...[
              const SizedBox(height: 20),
              _resultadoView(_resultado!, cs),
            ],
          ],
        ),
      ),
    );
  }

  // Linha "De X → Para Y" quando a origem veio do perfil do doador.
  Widget _linhaRota(ColorScheme cs) {
    final origem = _cidadeDoador ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Icon(Icons.my_location_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              origem,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: cs.onSurfaceVariant),
          ),
          Icon(Icons.place_outlined, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.destinoCidade,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultadoView(FreteEstimativa r, ColorScheme cs) {
    // Verificação de categoria: se o que a IA detectou no texto do item diverge
    // da categoria escolhida, avisa (sem bloquear — o cálculo já foi feito).
    final escolhida = _categoria;
    final detectada = r.categoriaDetectada;
    final divergeCategoria = escolhida != null &&
        escolhida.isNotEmpty &&
        detectada.isNotEmpty &&
        Categorias.normalizar(escolhida) != Categorias.normalizar(detectada);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (divergeCategoria) ...[
          _avisoCategoria(
            Categorias.rotulo(detectada),
            Categorias.rotulo(escolhida),
          ),
          const SizedBox(height: 12),
        ],
        // Resumo: rota + distância + peso.
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chipInfo(Icons.route_outlined, '${r.distanciaKm} km', cs),
            _chipInfo(
              Icons.scale_outlined,
              '${_pesoTexto(r.pesoKg)}${r.pesoEstimado ? " (estimado)" : ""}',
              cs,
            ),
            if (r.categoria.isNotEmpty)
              _chipInfo(Icons.category_outlined, r.categoria, cs),
          ],
        ),
        if (r.itemResumo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            r.itemResumo,
            style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 14),
        for (final m in r.modalidades) _cardModalidade(m, cs),
        const SizedBox(height: 12),
        // Aviso de estimativa — honestidade com o usuário.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 15, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                r.aviso.isNotEmpty
                    ? r.aviso
                    : 'Valores estimados por distância e peso — não são cotação oficial.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardModalidade(ModalidadeFrete m, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            m.ehLocal ? Icons.handshake_outlined : Icons.local_shipping_outlined,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nome,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (m.detalhe.isNotEmpty || m.prazoDias > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (m.prazoDias > 0)
                        '~${m.prazoDias} ${m.prazoDias == 1 ? "dia" : "dias"}',
                      if (m.detalhe.isNotEmpty) m.detalhe,
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            m.ehLocal ? 'Grátis' : 'R\$ ${m.valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: m.ehLocal ? AppColors.primary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Banner de aviso quando a categoria escolhida não parece combinar com o item.
  Widget _avisoCategoria(String detectada, String escolhida) {
    const cor = Color(0xFFF59E0B); // âmbar de alerta
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'O que você descreveu parece ser da categoria "$detectada", '
              'mas você escolheu "$escolhida". Confirme se está correto.',
              style: const TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipInfo(IconData icon, String texto, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(fontSize: 12, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  String _pesoTexto(double kg) {
    if (kg < 1) return '${(kg * 1000).round()} g';
    // Sem casas quando inteiro; uma casa caso contrário.
    return kg == kg.roundToDouble()
        ? '${kg.round()} kg'
        : '${kg.toStringAsFixed(1)} kg';
  }
}
