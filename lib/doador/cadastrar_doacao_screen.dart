import 'package:flutter/material.dart';

import '../doacao.dart';
import '../services/doacao_service.dart';

import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/inputs/app_text_field.dart';

class CadastrarDoacaoScreen extends StatefulWidget {
  final Doacao? doacao;

  const CadastrarDoacaoScreen({
    super.key,
    this.doacao,
  });

  @override
  State<CadastrarDoacaoScreen> createState() =>
      _CadastrarDoacaoScreenState();
}

class _CadastrarDoacaoScreenState
    extends State<CadastrarDoacaoScreen> {
  final nomeController = TextEditingController();

  final descricaoController =
      TextEditingController();

  final quantidadeController =
      TextEditingController();

  final DoacaoService _service =
      DoacaoService();

  bool carregando = false;

  bool urgente = false;

  bool produtoNovo = false;

  String categoria = 'Alimento';

  String tipo = 'Nova';

  bool get editando =>
      widget.doacao != null;

  @override
  void initState() {
    super.initState();

    preencherCampos();
  }

  void preencherCampos() {
    final doacao = widget.doacao;

    if (doacao == null) return;

    nomeController.text = doacao.nome;

    descricaoController.text =
        doacao.descricao;

    quantidadeController.text =
        doacao.quantidade.toString();

    categoria = doacao.categoria;

    tipo = doacao.tipo;

    urgente = doacao.urgente;

    produtoNovo = doacao.novo;
  }

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

    final quantidade = int.tryParse(
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
        id: widget.doacao?.id,
        nome: nomeController.text.trim(),
        descricao:
            descricaoController.text.trim(),
        quantidade: quantidade,
        categoria: categoria,
        tipo: tipo,
        urgente: urgente,
        novo: produtoNovo,
      );

      if (editando) {
        await _service.atualizarDoacao(
          doacao,
        );
      } else {
        await _service.cadastrarDoacao(
          doacao,
        );
      }

      if (!mounted) return;

      AppSnackbar.sucesso(
        context,
        editando
            ? 'Doação atualizada com sucesso!'
            : 'Doação cadastrada com sucesso!',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.erro(
        context,
        editando
            ? 'Erro ao atualizar doação.'
            : 'Erro ao cadastrar doação.',
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
        title: Text(
          editando
              ? 'Editar Doação'
              : 'Cadastrar Doação',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(28),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEAF6EE,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration:
                                const BoxDecoration(
                              color: Color(
                                0xFF0A8449,
                              ),
                              shape:
                                  BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons
                                  .volunteer_activism,
                              color:
                                  Colors.white,
                              size: 34,
                            ),
                          ),

                          const SizedBox(
                            width: 20,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  editando
                                      ? 'Editar Doação'
                                      : 'Nova Doação',
                                  style:
                                      const TextStyle(
                                    fontSize: 30,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  editando
                                      ? 'Atualize as informações da sua doação.'
                                      : 'Preencha os dados para disponibilizar uma nova doação.',
                                  style:
                                      TextStyle(
                                    color: Colors
                                        .grey
                                        .shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    const Text(
                      'Informações básicas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
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
                      maxLength: 200,
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Descrição da doação',
                        prefixIcon: Padding(
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
                      height: 32,
                    ),

                    const Divider(),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Classificação',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue: categoria,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Categoria',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Alimento',
                          child: Text(
                            'Alimento',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Roupa',
                          child: Text(
                            'Roupa',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Higiene',
                          child: Text(
                            'Higiene',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Brinquedo',
                          child: Text(
                            'Brinquedo',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Educação',
                          child: Text(
                            'Educação',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          categoria = value!;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue: tipo,
                      decoration:
                          const InputDecoration(
                        labelText: 'Tipo',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Nova',
                          child:
                              Text('Nova'),
                        ),
                        DropdownMenuItem(
                          value: 'Usado',
                          child:
                              Text('Usado'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          tipo = value!;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    const Divider(),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Preferências',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      value: urgente,
                      title: const Text(
                        'Prioridade alta',
                      ),
                      subtitle: const Text(
                        'Destacar esta doação.',
                      ),
                      activeThumbColor:
                          const Color(
                        0xFF0A8449,
                      ),
                      onChanged: (value) {
                        setState(() {
                          urgente = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      value: produtoNovo,
                      title: const Text(
                        'Item em bom estado',
                      ),
                      subtitle: const Text(
                        'Indica que o item está em excelentes condições.',
                      ),
                      activeThumbColor:
                          const Color(
                        0xFF0A8449,
                      ),
                      onChanged: (value) {
                        setState(() {
                          produtoNovo =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    AppButton(
                      texto: editando
                          ? 'ATUALIZAR DOAÇÃO'
                          : 'SALVAR DOAÇÃO',
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