import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/config_controller.dart';
import '../../models/campanha.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/categorias.dart';
import 'capa_categoria.dart';

/// Carrossel "vivo" de campanhas da Início: PageView com auto-avanço a cada
/// 5s em looping infinito, indicador de páginas e cards com capa ilustrativa
/// por categoria + barra de progresso animada.
///
/// O auto-avanço PAUSA enquanto o usuário está tocando/arrastando e retoma ao
/// soltar. O Timer é cancelado no dispose (nada roda com a tela desmontada).
class CarrosselCampanhas extends StatefulWidget {
  final List<Campanha> campanhas;
  final double altura;
  final void Function(Campanha) onTap;

  const CarrosselCampanhas({
    super.key,
    required this.campanhas,
    required this.altura,
    required this.onTap,
  });

  @override
  State<CarrosselCampanhas> createState() => _CarrosselCampanhasState();
}

class _CarrosselCampanhasState extends State<CarrosselCampanhas> {
  static const Duration _intervalo = Duration(seconds: 5);
  static const Duration _transicao = Duration(milliseconds: 500);

  // Página inicial bem alta para permitir arrastar "para trás" no looping.
  static const int _paginaBase = 5000;

  late final PageController _controller;
  Timer? _timer;
  int _paginaReal = 0; // índice dentro da lista (0..n-1), para o indicador

  int get _n => widget.campanhas.length;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.92,
      initialPage: _paginaBase * (_n == 0 ? 1 : _n),
    );
    _ligarTimer();
    // Reage ao liga/desliga da navegacao simplificada (inclusive no preview
    // da tela de Configuracoes): religa ou cancela o auto-avanco na hora E
    // reconstroi para mostrar/esconder o aviso de "modo simplificado".
    ConfigController.instance.addListener(_aoMudarConfig);
  }

  @override
  void dispose() {
    ConfigController.instance.removeListener(_aoMudarConfig);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Chamado quando as preferencias mudam (ex.: toggle da navegacao
  // simplificada): reavalia o auto-avanco e reconstroi a UI (aviso visivel).
  void _aoMudarConfig() {
    _ligarTimer();
    if (mounted) setState(() {});
  }

  void _ligarTimer() {
    _timer?.cancel();
    if (_n <= 1) return; // nada a rolar com 0 ou 1 campanha
    // Navegacao simplificada: sem auto-avanco (o usuario passa no swipe).
    if (ConfigController.instance.navegacaoSimplificada) return;
    _timer = Timer.periodic(_intervalo, (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(duration: _transicao, curve: Curves.easeOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_n == 0) return const SizedBox.shrink();

    // Uma campanha só: card único, sem looping (o PageView infinito repetiria
    // a MESMA campanha "espiando" nas bordas) e sem indicador.
    if (_n == 1) {
      return SizedBox(
          height: widget.altura, child: _card(widget.campanhas.first));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.altura,
          // Pausa o auto-avanço enquanto o dedo está na tela e retoma ao
          // soltar (também cobre o caso de o arrasto virar um fling).
          child: Listener(
            onPointerDown: (_) => _timer?.cancel(),
            onPointerUp: (_) => _ligarTimer(),
            onPointerCancel: (_) => _ligarTimer(),
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (p) => setState(() => _paginaReal = p % _n),
              itemBuilder: (_, i) => _card(widget.campanhas[i % _n]),
            ),
          ),
        ),
        if (_n > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(child: _indicador()),
        ],
        // Navegacao simplificada: sem auto-avanco. Deixa isso VISIVEL com um
        // aviso — o usuario passa os cards no swipe (nada se move sozinho).
        if (ConfigController.instance.navegacaoSimplificada && _n > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(child: _avisoSimplificado()),
        ],
      ],
    );
  }

  // Aviso discreto exibido quando a navegacao simplificada esta ligada: mostra
  // que o carrossel ficou estatico de proposito e convida ao swipe.
  Widget _avisoSimplificado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe_outlined, size: 15, color: AppColors.primary),
          SizedBox(width: 6),
          Text(
            'Modo simplificado — deslize para ver mais',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Bolinhas indicadoras: a ativa vira uma "pílula" verde.
  Widget _indicador() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _n; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _paginaReal ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == _paginaReal
                  ? AppColors.primary
                  : cs.outlineVariant,
              borderRadius: AppRadius.brSm,
            ),
          ),
      ],
    );
  }

  Widget _card(Campanha c) {
    final cs = Theme.of(context).colorScheme;
    final categoria = (c.categoria?.trim().isNotEmpty ?? false)
        ? c.categoria!
        : 'Doações';
    final double prog = (c.progresso.clamp(0, 100)) / 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onTap(c),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CapaCategoria(
                  categoria: categoria,
                  altura: 76,
                  selo: c.destaque ? _seloDestaque() : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            c.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                                fontSize: 15),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.ongNome ?? 'ONG',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                        const Spacer(),
                        // Barra de progresso ANIMADA: cresce de 0 até o valor
                        // real quando o card aparece. Com navegação
                        // simplificada ligada, aparece direto no valor final
                        // (sem animação).
                        if (ConfigController.instance.navegacaoSimplificada)
                          _barraProgresso(prog, categoria)
                        else
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: prog),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, valor, _) =>
                                _barraProgresso(valor, categoria),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'R\$ ${c.valorArrecadado.toStringAsFixed(0)} de R\$ ${c.metaValor.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _chipProgresso(c.progresso),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Barra de progresso da campanha na cor da categoria.
  Widget _barraProgresso(double valor, String categoria) {
    return ClipRRect(
      borderRadius: AppRadius.brSm,
      child: LinearProgressIndicator(
        value: valor,
        minHeight: 8,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(Categorias.cor(categoria)),
      ),
    );
  }

  Widget _chipProgresso(int progresso) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.brSm,
      ),
      child: Text(
        '$progresso%',
        style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _seloDestaque() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.onPrimary,
        borderRadius: AppRadius.brSm,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: AppColors.ouro),
          SizedBox(width: 3),
          Text('Destaque',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
