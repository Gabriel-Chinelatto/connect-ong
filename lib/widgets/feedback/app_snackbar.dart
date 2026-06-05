import 'package:flutter/material.dart';

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