import 'package:flutter/material.dart';

/// Indicador de carregamento centralizado, com mensagem opcional.
///
/// Usado enquanto telas aguardam respostas da API.
class LoadingWidget extends StatelessWidget {

  final String? mensagem;

  const LoadingWidget({
    super.key,
    this.mensagem,
  });

  @override
  Widget build(BuildContext context) {

    return Center(

      child: Column(

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          const SizedBox(

            width: 42,

            height: 42,

            child: CircularProgressIndicator(

              strokeWidth: 4,
            ),
          ),

          if (mensagem != null) ...[

            const SizedBox(
              height: 20,
            ),

            Text(

              mensagem!,

              style: const TextStyle(

                fontSize: 16,

                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}