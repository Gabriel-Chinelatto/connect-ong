import 'package:flutter/material.dart';

/// Botao primario padrao do app (largura total, altura fixa).
///
/// Reutilizado em formularios e telas de acao. Quando [carregando] e true,
/// desabilita o toque e mostra um indicador de progresso no lugar do texto.
class AppButton extends StatelessWidget {

  final String texto;

  final VoidCallback onPressed;

  final bool carregando;

  const AppButton({

    super.key,

    required this.texto,

    required this.onPressed,

    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(

      width: double.infinity,

      height: 58,

      child: ElevatedButton(

        onPressed:
            carregando
                ? null
                : onPressed,

        child:
            carregando

                ? const SizedBox(

                    width: 24,
                    height: 24,

                    child:
                        CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )

                : Text(

                    texto,

                    style: const TextStyle(

                      fontSize: 18,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
      ),
    );
  }
}