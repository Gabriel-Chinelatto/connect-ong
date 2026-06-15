import 'package:flutter/material.dart';

import '../../doacao.dart';

class DoacaoCard extends StatelessWidget {
  final Doacao doacao;

  final VoidCallback? onEditar;
  final VoidCallback? onExcluir;

  const DoacaoCard({
    super.key,
    required this.doacao,
    this.onEditar,
    this.onExcluir,
  });

  IconData _iconeCategoria() {
    switch (doacao.categoria) {
      case 'Alimento':
        return Icons.restaurant;

      case 'Roupa':
        return Icons.checkroom;

      case 'Higiene':
        return Icons.health_and_safety;

      case 'Educação':
        return Icons.school;

      case 'Brinquedo':
        return Icons.toys;

      default:
        return Icons.volunteer_activism;
    }
  }

  Color _corCategoria() {
    switch (doacao.categoria) {
      case 'Alimento':
        return Colors.green;

      case 'Roupa':
        return Colors.blue;

      case 'Higiene':
        return Colors.purple;

      case 'Educação':
        return Colors.orange;

      case 'Brinquedo':
        return Colors.pink;

      default:
        return const Color(0xFF0A8449);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corCategoria();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      cor.withOpacity(0.12),
                  child: Icon(
                    _iconeCategoria(),
                    color: cor,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    doacao.nome,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                      color: cor,
                    ),
                  ),
                ),

                Tooltip(
                  message: 'Editar',
                  child: IconButton(
                    onPressed: onEditar,
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    color: Colors.blue,
                  ),
                ),

                Tooltip(
                  message: 'Excluir',
                  child: IconButton(
                    onPressed: onExcluir,
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              doacao.descricao,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    _iconeCategoria(),
                    size: 18,
                    color: cor,
                  ),
                  label: Text(
                    doacao.categoria,
                  ),
                ),

                Chip(
                  avatar: const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                  ),
                  label: Text(
                    doacao.tipo,
                  ),
                ),

                Chip(
                  avatar: const Icon(
                    Icons.numbers,
                    size: 18,
                  ),
                  label: Text(
                    '${doacao.quantidade} unidades',
                  ),
                ),

                if (doacao.urgente)
                  const Chip(
                    backgroundColor:
                        Color(0xFFFFEBEE),
                    avatar: Icon(
                      Icons.warning_amber,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: Text(
                      'Urgente',
                    ),
                  ),

                if (doacao.novo)
                  const Chip(
                    backgroundColor:
                        Color(0xFFE8F5E9),
                    avatar: Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 18,
                    ),
                    label: Text(
                      'Novo',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}