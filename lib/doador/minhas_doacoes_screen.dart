import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../doacao.dart';
import '../services/doacao_service.dart';
import '../services/relatorio_pdf_service.dart';
import '../services/session_service.dart';

import '../widgets/cards/doacao_card.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/loading_widget.dart';

import 'cadastrar_doacao_screen.dart';
import '../widgets/common/app_footer.dart';

class MinhasDoacoesScreen extends StatefulWidget {
  const MinhasDoacoesScreen({
    super.key,
  });

  @override
  State<MinhasDoacoesScreen> createState() =>
      _MinhasDoacoesScreenState();
}

class _MinhasDoacoesScreenState
    extends State<MinhasDoacoesScreen> {
  final DoacaoService _service =
      DoacaoService();

  bool carregando = true;

  List<Doacao> doacoes = [];

  @override
  void initState() {
    super.initState();

    carregarDoacoes();
  }

  Future<void> carregarDoacoes() async {
    setState(() {
      carregando = true;
    });

    try {
      final lista =
          await _service.listarDoacoes();

      if (!mounted) return;

      setState(() {
        doacoes = lista;
      });
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.erro(
        context,
        'Não foi possível carregar as doações. Verifique a conexão com a API.',
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> abrirFormulario([
    Doacao? doacao,
  ]) async {
    final atualizado =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CadastrarDoacaoScreen(
          doacao: doacao,
        ),
      ),
    );

    if (atualizado == true) {
      carregarDoacoes();
    }
  }

  Future<void> excluirDoacao(
    Doacao doacao,
  ) async {
    final confirmar =
        await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text(
                    'Excluir doação',
                  ),
                  content: Text(
                    'Deseja excluir "${doacao.nome}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          true,
                        );
                      },
                      child: const Text(
                        'Excluir',
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;

    if (!confirmar) return;

    try {
      await _service.excluirDoacao(
        doacao.id!,
      );

      if (!mounted) return;

      AppSnackbar.sucesso(
        context,
        'Doação excluída com sucesso.',
      );

      carregarDoacoes();
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.erro(
        context,
        'Erro ao excluir doação.',
      );
    }
  }

  Future<void> exportarPdf() async {
    if (doacoes.isEmpty) return;

    try {
      final usuario =
          await SessionService().obterUsuario();

      if (!mounted) return;

      final bytes = await RelatorioPdfService
          .historicoDoacoes(
        doacoes,
        nomeDoador: usuario?.nome,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      if (!mounted) return;

      AppSnackbar.erro(
        context,
        'Não foi possível gerar o PDF.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Doações',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
            tooltip: 'Exportar PDF',
            onPressed: doacoes.isEmpty
                ? null
                : exportarPdf,
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            const Color(0xFF0A8449),
        elevation: 6,
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          'Nova Doação',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () {
          abrirFormulario();
        },
      ),
      body: carregando
          ? const LoadingWidget(
              mensagem:
                  'Carregando doações...',
            )
          : RefreshIndicator(
              onRefresh: carregarDoacoes,
              child: ListView(
                padding:
                    const EdgeInsets.all(24),
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
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          'Gerencie suas doações',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          '${doacoes.length} doações cadastradas',
                          style: TextStyle(
                            color: Colors
                                .grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (doacoes.isEmpty)
                    SizedBox(
                      height: 320,
                      child: Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons
                                  .volunteer_activism_outlined,
                              size: 72,
                              color:
                                  Color(0xFFB0BEC5),
                            ),

                            SizedBox(
                              height: 16,
                            ),

                            Text(
                              'Nenhuma doação cadastrada',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),

                            SizedBox(
                              height: 8,
                            ),

                            Text(
                              'Clique em "Nova Doação" para começar.',
                              style: TextStyle(
                                color:
                                    Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ...doacoes.map(
                    (doacao) => DoacaoCard(
                      doacao: doacao,
                      onEditar: () {
                        abrirFormulario(
                          doacao,
                        );
                      },
                      onExcluir: () {
                        excluirDoacao(
                          doacao,
                        );
                      },
                    ),
                    
                  ),
                  const SizedBox(
                 height: 24,
                  ),

                const AppFooter(),
                ],
              ),
            ),
    );
  }
}