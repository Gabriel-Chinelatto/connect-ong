import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Visualização de uma imagem (bytes) em TELA CHEIA: fundo preto, pinça para
/// zoom (InteractiveViewer) e botão de fechar. Reutilizada pelas fotos do
/// local da ONG, pelas fotos das prestações de contas e pelos anexos do chat.
class VisualizadorImagem extends StatelessWidget {
  final Uint8List bytes;
  final String? titulo;

  const VisualizadorImagem({super.key, required this.bytes, this.titulo});

  /// Abre o visualizador por cima da tela atual.
  static void abrir(BuildContext context, Uint8List bytes, {String? titulo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisualizadorImagem(bytes: bytes, titulo: titulo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: titulo == null
            ? null
            : Text(
                titulo!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
