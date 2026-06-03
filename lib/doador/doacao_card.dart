import 'package:flutter/material.dart';
import 'package:flutter_application_1/doacao.dart';

class DoacaoCard extends StatelessWidget {
  final Doacao doacao;
  const DoacaoCard({super.key, required this.doacao});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      color: Colors.white.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doacao.nome,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A8449)),
            ),
            const SizedBox(height: 8),
            Text(
              doacao.descricao,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, size: 18, color: Color(0xFF0A8449)),
                const SizedBox(width: 6),
                Text('Categoria: ${doacao.categoria}', style: const TextStyle(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.confirmation_number, size: 18, color: Color(0xFF0A8449)),
                const SizedBox(width: 6),
                Text('Quantidade: ${doacao.quantidade}', style: const TextStyle(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.style, size: 18, color: Color(0xFF0A8449)),
                const SizedBox(width: 6),
                Text('Tipo: ${doacao.tipo}', style: const TextStyle(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.priority_high, size: 18, color: Color(0xFF0A8449)),
                const SizedBox(width: 6),
                Text('Urgente: ${doacao.urgente ? "Sim" : "Não"}', style: const TextStyle(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.new_releases, size: 18, color: Color(0xFF0A8449)),
                const SizedBox(width: 6),
                Text('Produto novo: ${doacao.novo ? "Sim" : "Não"}', style: const TextStyle(fontSize: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
