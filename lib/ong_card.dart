import 'package:flutter/material.dart';
import 'package:flutter_application_1/ong.dart';

class OngCard extends StatelessWidget {
  final Ong ong;
  // Callback para a função de edição (recebe a ONG)
  final void Function(Ong) onEdit;
  // Callback para a função de deleção (recebe o ID da ONG)
  final void Function(int) onDelete;

  const OngCard({
    super.key,
    required this.ong,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ong.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0A8449)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Botões de Ação
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => onEdit(ong), // Chama a função de edição
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Confirmação antes de deletar
                        if (ong.id != null) {
                          _confirmDelete(context, ong.id!);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Text('Email: ${ong.email}'),
            Text('Telefone: ${ong.telefone}'),
            Text('Cidade: ${ong.cidade}'),
            const SizedBox(height: 8),
            Text('Descrição: ${ong.descricao}'),
            if (ong.id != null) Text('ID: ${ong.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
  
  // Função para exibir um diálogo de confirmação de exclusão
  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja deletar a ONG ${ong.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete(id); // Chama a função de deleção na tela principal
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}