import 'package:flutter/material.dart';

/// Helper para exibir snackbars padronizados de feedback ao usuario.
///
/// Oferece [sucesso] (verde) e [erro] (vermelho), ambos no estilo flutuante e
/// arredondado da marca.
class AppSnackbar {

  static void sucesso(
    BuildContext context,
    String mensagem,
  ) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content: Text(
          mensagem,
        ),

        backgroundColor:
            Colors.green,

        behavior:
            SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(

          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
    );
  }

  static void erro(
    BuildContext context,
    String mensagem,
  ) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content: Text(
          mensagem,
        ),

        backgroundColor:
            Colors.redAccent,

        behavior:
            SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(

          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
    );
  }
}