import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../doacao.dart';
import '../services/doacao_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../utils/categorias.dart';
import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/inputs/app_text_field.dart';

/// Formulario de cadastro/edicao de uma doacao de item (nome, descricao,
/// quantidade, categoria, tipo, urgencia). Quando recebe uma [Doacao] no
/// construtor, opera em modo edicao; caso contrario, cria uma nova.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
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

  String categoria = 'Alimentos';

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

    // Normaliza valores legados ("Alimento", "Educação"...) para o canonico,
    // senao o Dropdown nao encontra o valor entre os itens.
    categoria = Categorias.normalizar(doacao.categoria);

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editando
              ? 'Editar Doação'
              : 'Cadastrar Doação',
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: AppRadius.brXl,
                border:
                    Border.all(color: cs.outlineVariant),
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
                        color: AppColors.primary
                            .withValues(alpha: 0.10),
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
                              color:
                                  AppColors.primary,
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
                                      ? 'Editar doação'
                                      : 'Nova doação',
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

                                // Deixa claro que a oferta NÃO é direcionada
                                // a uma ONG específica: fica disponível para
                                // qualquer ONG que precise.
                                Text(
                                  editando
                                      ? 'Atualize as informações da sua doação.'
                                      : 'Preencha os dados para disponibilizar '
                                          'sua doação a qualquer ONG que '
                                          'precise. As ONGs interessadas '
                                          'poderão entrar em contato com você.',
                                  style:
                                      TextStyle(
                                    color: cs
                                        .onSurfaceVariant,
                                    fontSize: 16,
                                    height: 1.4,
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
                      maxLength: 60,
                      textInputAction:
                          TextInputAction.next,
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
                      keyboardType:
                          TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                      ],
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
                      // Lista canonica unica (utils/categorias.dart), espelhada
                      // no backend. Se uma doacao antiga tiver categoria fora
                      // da lista, ela entra como item extra para nao quebrar.
                      items: [
                        for (final c
                            in Categorias.todas)
                          DropdownMenuItem(
                            value: c.valor,
                            child: Row(
                              children: [
                                Icon(c.icone,
                                    size: 18,
                                    color: AppColors
                                        .primary),
                                const SizedBox(
                                    width: 8),
                                Text(c.rotulo),
                              ],
                            ),
                          ),
                        if (!Categorias.todas.any(
                            (c) =>
                                c.valor ==
                                categoria))
                          DropdownMenuItem(
                            value: categoria,
                            child:
                                Text(categoria),
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
                          AppColors.primary,
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
                          AppColors.primary,
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