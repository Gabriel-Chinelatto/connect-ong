import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/categorias.dart';

/// Animação festiva de sucesso: círculo verde que "nasce" com um checkmark
/// desenhado traço a traço + uma chuva de confetes nas cores da marca.
///
/// Implementada só com AnimationController + CustomPainter (sem pacotes novos).
/// Usada no comprovante do fluxo PIX.
class CelebracaoSucesso extends StatefulWidget {
  final double tamanho;

  const CelebracaoSucesso({super.key, this.tamanho = 160});

  @override
  State<CelebracaoSucesso> createState() => _CelebracaoSucessoState();
}

class _CelebracaoSucessoState extends State<CelebracaoSucesso>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Confete> _confetes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // Confetes pré-sorteados (posição, cor, tamanho e rotação) para o painter
    // ser puro e barato a cada frame.
    final rnd = Random();
    final cores = <Color>[
      AppColors.primary,
      AppColors.ouro,
      for (final c in Categorias.todas) c.cor,
    ];
    _confetes = List.generate(26, (_) {
      return _Confete(
        angulo: rnd.nextDouble() * 2 * pi,
        velocidade: 0.55 + rnd.nextDouble() * 0.45,
        tamanho: 3.0 + rnd.nextDouble() * 4.0,
        rotacao: rnd.nextDouble() * 2 * pi,
        giro: (rnd.nextDouble() - 0.5) * 6,
        cor: cores[rnd.nextInt(cores.length)],
        retangular: rnd.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pagamento confirmado',
      child: SizedBox(
        width: widget.tamanho,
        height: widget.tamanho,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => CustomPaint(
            painter: _CelebracaoPainter(
              progresso: _controller.value,
              confetes: _confetes,
            ),
          ),
        ),
      ),
    );
  }
}

class _Confete {
  final double angulo; // direção do voo (radianos)
  final double velocidade; // multiplicador da distância percorrida
  final double tamanho;
  final double rotacao; // rotação inicial
  final double giro; // velocidade de rotação
  final Color cor;
  final bool retangular; // retângulo ou círculo

  const _Confete({
    required this.angulo,
    required this.velocidade,
    required this.tamanho,
    required this.rotacao,
    required this.giro,
    required this.cor,
    required this.retangular,
  });
}

class _CelebracaoPainter extends CustomPainter {
  final double progresso; // 0..1 da animação inteira
  final List<_Confete> confetes;

  _CelebracaoPainter({required this.progresso, required this.confetes});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raioMax = size.shortestSide / 2;

    _pintarConfetes(canvas, centro, raioMax);
    _pintarCirculo(canvas, centro, raioMax);
    _pintarCheck(canvas, centro, raioMax);
  }

  // Círculo verde que cresce com efeito elástico (0% → 45% da animação).
  void _pintarCirculo(Canvas canvas, Offset centro, double raioMax) {
    final t = (progresso / 0.45).clamp(0.0, 1.0);
    final escala = Curves.elasticOut.transform(t);
    final raio = raioMax * 0.42 * escala;
    if (raio <= 0) return;
    canvas.drawCircle(centro, raio, Paint()..color = AppColors.primary);
  }

  // Checkmark desenhado traço a traço (35% → 70% da animação).
  void _pintarCheck(Canvas canvas, Offset centro, double raioMax) {
    final t = ((progresso - 0.35) / 0.35).clamp(0.0, 1.0);
    if (t <= 0) return;

    final r = raioMax * 0.42;
    final caminho = Path()
      ..moveTo(centro.dx - r * 0.45, centro.dy + r * 0.02)
      ..lineTo(centro.dx - r * 0.12, centro.dy + r * 0.36)
      ..lineTo(centro.dx + r * 0.50, centro.dy - r * 0.32);

    // Extrai só o trecho do caminho proporcional ao progresso.
    final medida = caminho.computeMetrics().first;
    final parcial = medida.extractPath(
        0, medida.length * Curves.easeOutCubic.transform(t));

    canvas.drawPath(
      parcial,
      Paint()
        ..color = AppColors.onPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // Confetes voando do centro para fora, com fade no final (15% → 100%).
  void _pintarConfetes(Canvas canvas, Offset centro, double raioMax) {
    final t = ((progresso - 0.15) / 0.85).clamp(0.0, 1.0);
    if (t <= 0) return;

    final avanco = Curves.easeOutCubic.transform(t);
    final opacidade = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    final paint = Paint();

    for (final c in confetes) {
      final distancia = raioMax * (0.30 + 0.70 * avanco * c.velocidade);
      // Leve "queda" (gravidade) para o voo parecer natural.
      final gravidade = raioMax * 0.25 * avanco * avanco;
      final pos = centro +
          Offset(cos(c.angulo) * distancia,
              sin(c.angulo) * distancia + gravidade);

      paint.color = c.cor.withValues(alpha: opacidade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(c.rotacao + c.giro * avanco);
      if (c.retangular) {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: c.tamanho, height: c.tamanho * 1.8),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, c.tamanho / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebracaoPainter old) =>
      old.progresso != progresso || old.confetes != confetes;
}
