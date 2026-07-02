import 'package:flutter/material.dart';

import '../../utils/categorias.dart';

/// Capa visual de um card baseada na CATEGORIA (estilo marketplace): um
/// gradiente na cor da categoria com o icone em marca d'água. Substitui a
/// foto enquanto o upload de imagens não existe — e serve de fallback depois.
class CapaCategoria extends StatelessWidget {
  final String categoria;
  final double altura;

  /// Selo opcional exibido no canto superior esquerdo (ex.: "URGENTE").
  final Widget? selo;

  const CapaCategoria({
    super.key,
    required this.categoria,
    this.altura = 88,
    this.selo,
  });

  @override
  Widget build(BuildContext context) {
    final cor = Categorias.cor(categoria);
    return SizedBox(
      height: altura,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cor.withValues(alpha: 0.85),
                  cor,
                ],
              ),
            ),
          ),
          // Icone em marca d'água, sangrando na borda direita.
          Positioned(
            right: -12,
            bottom: -14,
            child: Icon(
              Categorias.icone(categoria),
              size: altura * 1.1,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          // Rotulo da categoria.
          Positioned(
            left: 12,
            bottom: 10,
            child: Row(
              children: [
                Icon(Categorias.icone(categoria),
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  Categorias.rotulo(categoria),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (selo != null) Positioned(left: 12, top: 10, child: selo!),
        ],
      ),
    );
  }
}
