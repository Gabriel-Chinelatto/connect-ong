import 'package:flutter/material.dart';

import '../doacao.dart';

import '../services/doacao_service.dart';

import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/inputs/app_text_field.dart';

class CadastrarDoacaoScreen
    extends StatefulWidget {

  const CadastrarDoacaoScreen({
    super.key,
  });

  @override
  State<CadastrarDoacaoScreen>
      createState() =>
          _CadastrarDoacaoScreenState();
}

class _CadastrarDoacaoScreenState
    extends State<CadastrarDoacaoScreen> {

  final nomeController =
      TextEditingController();

  final descricaoController =
      TextEditingController();

  final quantidadeController =
      TextEditingController();

  final DoacaoService _service =
      DoacaoService();

  bool carregando = false;

  bool urgente = false;

  bool produtoNovo = false;

  String categoria =
      'Alimento';

  String tipo =
      'Produto';

  Future<void> salvarDoacao() async {

    FocusScope.of(context).unfocus();

    if (nomeController.text
        .trim()
        .isEmpty) {

      AppSnackbar.erro(

        context,

        'Informe o nome da doação.',
      );

      return;
    }

    if (quantidadeController.text
        .trim()
        .isEmpty) {

      AppSnackbar.erro(

        context,

        'Informe a quantidade.',
      );

      return;
    }

    final quantidade =
        int.tryParse(
      quantidadeController.text,
    );

    if (quantidade == null ||
        quantidade <= 0) {

      AppSnackbar.erro(

        context,

        'Quantidade inválida.',
      );

      return;
    }

    setState(() {

      carregando = true;
    });

    try {

      final doacao = Doacao(

        nome:
            nomeController.text.trim(),

        descricao:
            descricaoController.text
                .trim(),

        quantidade: quantidade,

        categoria: categoria,

        tipo: tipo,

        urgente: urgente,

        novo: produtoNovo,
      );

      await _service.cadastrarDoacao(
        doacao,
      );

      if (!mounted) return;

      AppSnackbar.sucesso(

        context,

        'Doação cadastrada com sucesso!',
      );

      nomeController.clear();

      descricaoController.clear();

      quantidadeController.clear();

      setState(() {

        urgente = false;

        produtoNovo = false;

        categoria = 'Alimento';

        tipo = 'Produto';
      });

    } catch (e) {

      if (!mounted) return;

      AppSnackbar.erro(

        context,

        'Erro ao cadastrar doação.',
      );

    } finally {

      if (mounted) {

        setState(() {

          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {

    nomeController.dispose();

    descricaoController.dispose();

    quantidadeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          'Cadastrar Doação',
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(24),

        child: Center(

          child: Container(

            constraints:
                const BoxConstraints(
              maxWidth: 700,
            ),

            child: Card(

              child: Padding(

                padding:
                    const EdgeInsets.all(32),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(

                      'Nova Doação',

                      style: TextStyle(

                        fontSize: 30,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(

                      'Preencha as informações da doação.',

                      style: TextStyle(

                        color:
                            Colors.grey.shade700,

                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    AppTextField(

                      controller:
                          nomeController,

                      hint:
                          'Nome da doação',

                      icon:
                          Icons.favorite,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    TextField(

                      controller:
                          descricaoController,

                      maxLines: 4,

                      decoration:
                          const InputDecoration(

                        hintText:
                            'Descrição',

                        prefixIcon:
                            Padding(

                          padding:
                              EdgeInsets.only(
                            bottom: 80,
                          ),

                          child: Icon(
                            Icons.description,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    AppTextField(

                      controller:
                          quantidadeController,

                      hint: 'Quantidade',

                      icon:
                          Icons.numbers,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    DropdownButtonFormField<String>(

                      value: categoria,

                      decoration:
                          const InputDecoration(

                        labelText:
                            'Categoria',
                      ),

                      items: const [

                        DropdownMenuItem(

                          value:
                              'Alimento',

                          child: Text(
                            'Alimento',
                          ),
                        ),

                        DropdownMenuItem(

                          value:
                              'Roupa',

                          child: Text(
                            'Roupa',
                          ),
                        ),

                        DropdownMenuItem(

                          value:
                              'Higiene',

                          child: Text(
                            'Higiene',
                          ),
                        ),

                        DropdownMenuItem(

                          value:
                              'Brinquedo',

                          child: Text(
                            'Brinquedo',
                          ),
                        ),
                      ],

                      onChanged: (value) {

                        setState(() {

                          categoria =
                              value!;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    DropdownButtonFormField<String>(

                      value: tipo,

                      decoration:
                          const InputDecoration(

                        labelText: 'Tipo',
                      ),

                      items: const [

                        DropdownMenuItem(

                          value:
                              'Produto',

                          child: Text(
                            'Produto',
                          ),
                        ),

                        DropdownMenuItem(

                          value:
                              'Serviço',

                          child: Text(
                            'Serviço',
                          ),
                        ),
                      ],

                      onChanged: (value) {

                        setState(() {

                          tipo = value!;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    SwitchListTile(

                      value: urgente,

                      title: const Text(
                        'Doação urgente',
                      ),

                      activeColor:
                          const Color(
                        0xFF2F8F46,
                      ),

                      onChanged: (value) {

                        setState(() {

                          urgente = value;
                        });
                      },
                    ),

                    SwitchListTile(

                      value: produtoNovo,

                      title: const Text(
                        'Produto novo',
                      ),

                      activeColor:
                          const Color(
                        0xFF2F8F46,
                      ),

                      onChanged: (value) {

                        setState(() {

                          produtoNovo = value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    AppButton(

                      texto:
                          'SALVAR DOAÇÃO',

                      carregando:
                          carregando,

                      onPressed:
                          salvarDoacao,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}