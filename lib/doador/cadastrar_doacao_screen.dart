import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_application_1/doacao.dart';

import '../widgets/doacao_card.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

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

  final _formKey =
      GlobalKey<FormState>();

  String? _nomeDoacao;

  String? _descricaoDoacao;

  int? _quantidade;

  String? _tipoDoacao;

  final List<String>
      _categorias = [

    'Alimento',

    'Roupa',

    'Brinquedo',

    'Móvel',
  ];

  String? _categoriaSelecionada;

  bool _isUrgente = false;

  bool _isNovo = false;

  bool carregando = false;

  final List<Doacao> _doacoes = [];

  static const String _baseUrl =
      'http://localhost:8080/doacoes';

  Future<void>
      _salvarDoacaoAPI() async {

    final body = {

      "nome": _nomeDoacao,

      "descricao":
          _descricaoDoacao,

      "quantidade":
          _quantidade,

      "categoria":
          _categoriaSelecionada,

      "tipo": _tipoDoacao,

      "urgente": _isUrgente,

      "novo": _isNovo
    };

    try {

      final response =
          await http.post(

        Uri.parse(_baseUrl),

        headers: {

          'Content-Type':
              'application/json'
        },

        body: jsonEncode(body),
      );

      if (response.statusCode ==
              200 ||
          response.statusCode ==
              201) {

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(

            behavior:
                SnackBarBehavior
                    .floating,

            backgroundColor:
                const Color(
              0xFF0A8449,
            ),

            shape:
                RoundedRectangleBorder(

              borderRadius:
                  BorderRadius
                      .circular(
                16,
              ),
            ),

            content: Text(

              "Doação cadastrada com sucesso",

              style:
                  GoogleFonts
                      .poppins(),
            ),
          ),
        );

      } else {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(

            behavior:
                SnackBarBehavior
                    .floating,

            backgroundColor:
                Colors.red,

            content: Text(

              "Erro ${response.statusCode}",

              style:
                  GoogleFonts
                      .poppins(),
            ),
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          behavior:
              SnackBarBehavior
                  .floating,

          backgroundColor:
              Colors.red,

          content: Text(

            "Erro de conexão",

            style:
                GoogleFonts
                    .poppins(),
          ),
        ),
      );
    }
  }

  void _salvarDoacao() async {

    final isValid =
        _formKey.currentState
            ?.validate() ??
        false;

    final tipoValido =
        _tipoDoacao != null;

    if (!isValid ||
        !tipoValido) {

      setState(() {});

      return;
    }

    _formKey.currentState?.save();

    setState(() {
      carregando = true;
    });

    await _salvarDoacaoAPI();

    setState(() {

      _doacoes.insert(

        0,

        Doacao(

          nome: _nomeDoacao!,

          descricao:
              _descricaoDoacao!,

          quantidade:
              _quantidade!,

          categoria:
              _categoriaSelecionada!,

          tipo: _tipoDoacao!,

          urgente:
              _isUrgente,

          novo: _isNovo,
        ),
      );

      carregando = false;

      _formKey.currentState
          ?.reset();

      _tipoDoacao = null;

      _categoriaSelecionada =
          null;

      _isUrgente = false;

      _isNovo = false;
    });
  }

  InputDecoration _inputStyle(
    String label,
    IconData icon,
  ) {

    return InputDecoration(

      labelText: label,

      labelStyle:
          GoogleFonts.poppins(),

      prefixIcon: Icon(

        icon,

        color:
            const Color(
          0xFF0A8449,
        ),
      ),

      filled: true,

      fillColor:
          const Color(
        0xFFF7F7F7,
      ),

      border:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        borderSide:
            BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        borderSide:
            const BorderSide(

          color:
              Color(
            0xFF0A8449,
          ),

          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(
        0xFFF3F7F5,
      ),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
            Colors.transparent,

        foregroundColor:
            Colors.black87,

        centerTitle: true,

        title: Text(

          'Cadastrar Doação',

          style:
              GoogleFonts.poppins(

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      body: Padding(

        padding:
            const EdgeInsets.symmetric(

          horizontal: 22,

          vertical: 12,
        ),

        child: ListView(

          physics:
              const BouncingScrollPhysics(),

          children: [

            Container(

              padding:
                  const EdgeInsets.all(
                24,
              ),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  30,
                ),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black
                        .withOpacity(
                      0.04,
                    ),

                    blurRadius: 18,

                    offset:
                        const Offset(
                      0,
                      8,
                    ),
                  ),
                ],
              ),

              child: Form(

                key: _formKey,

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,

                  children: [

                    Text(

                      'Informações da Doação',

                      style:
                          GoogleFonts
                              .poppins(

                        fontSize: 20,

                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    TextFormField(

                      decoration:
                          _inputStyle(

                        'Nome da Doação',

                        Icons
                            .favorite_border,
                      ),

                      onSaved: (val) =>
                          _nomeDoacao =
                              val,

                      validator: (val) {

                        if (val ==
                                null ||
                            val
                                .trim()
                                .isEmpty) {

                          return 'Informe o nome da doação';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    TextFormField(

                      maxLines: 4,

                      decoration:
                          _inputStyle(

                        'Descrição',

                        Icons
                            .description_outlined,
                      ),

                      onSaved: (val) =>
                          _descricaoDoacao =
                              val,

                      validator: (val) {

                        if (val ==
                                null ||
                            val
                                .trim()
                                .isEmpty) {

                          return 'Informe uma descrição';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    TextFormField(

                      keyboardType:
                          TextInputType
                              .number,

                      decoration:
                          _inputStyle(

                        'Quantidade',

                        Icons
                            .numbers_outlined,
                      ),

                      onSaved: (val) {

                        _quantidade =
                            int.tryParse(
                          val ?? '',
                        );
                      },

                      validator: (val) {

                        if (val ==
                                null ||
                            val
                                .trim()
                                .isEmpty) {

                          return 'Informe a quantidade';
                        }

                        final n =
                            int.tryParse(
                          val,
                        );

                        if (n ==
                                null ||
                            n <= 0) {

                          return 'Quantidade inválida';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    DropdownButtonFormField<
                        String>(

                      value:
                          _categoriaSelecionada,

                      decoration:
                          _inputStyle(

                        'Categoria',

                        Icons
                            .category_outlined,
                      ),

                      items:
                          _categorias
                              .map(

                        (
                          categoria,
                        ) {

                          return DropdownMenuItem<

                              String>(

                            value:
                                categoria,

                            child: Text(

                              categoria,

                              style:
                                  GoogleFonts
                                      .poppins(),
                            ),
                          );
                        },
                      ).toList(),

                      onChanged: (val) {

                        setState(() {

                          _categoriaSelecionada =
                              val;
                        });
                      },

                      validator: (val) {

                        if (val ==
                            null) {

                          return 'Selecione uma categoria';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    Text(

                      'Tipo da Doação',

                      style:
                          GoogleFonts
                              .poppins(

                        fontWeight:
                            FontWeight
                                .w600,

                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Container(

                      decoration:
                          BoxDecoration(

                        color:
                            const Color(
                          0xFFF5F5F5,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),

                      child: Column(

                        children: [

                          RadioListTile<
                              String>(

                            title: Text(

                              'Nova',

                              style:
                                  GoogleFonts
                                      .poppins(),
                            ),

                            value:
                                'Nova',

                            groupValue:
                                _tipoDoacao,

                            activeColor:
                                const Color(
                              0xFF0A8449,
                            ),

                            onChanged:
                                (val) {

                              setState(() {

                                _tipoDoacao =
                                    val;
                              });
                            },
                          ),

                          RadioListTile<
                              String>(

                            title: Text(

                              'Usada',

                              style:
                                  GoogleFonts
                                      .poppins(),
                            ),

                            value:
                                'Usada',

                            groupValue:
                                _tipoDoacao,

                            activeColor:
                                const Color(
                              0xFF0A8449,
                            ),

                            onChanged:
                                (val) {

                              setState(() {

                                _tipoDoacao =
                                    val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_tipoDoacao ==
                        null)

                      Padding(

                        padding:
                            const EdgeInsets.only(
                          top: 8,
                          left: 8,
                        ),

                        child: Text(

                          'Selecione o tipo da doação',

                          style:
                              GoogleFonts
                                  .poppins(

                            color:
                                Colors.red,

                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(
                      height: 18,
                    ),

                    SwitchListTile(

                      activeColor:
                          const Color(
                        0xFF0A8449,
                      ),

                      title: Text(

                        'Doação urgente',

                        style:
                            GoogleFonts
                                .poppins(),
                      ),

                      value: _isUrgente,

                      onChanged: (
                        val,
                      ) {

                        setState(() {

                          _isUrgente =
                              val;
                        });
                      },
                    ),

                    SwitchListTile(

                      activeColor:
                          const Color(
                        0xFF0A8449,
                      ),

                      title: Text(

                        'Produto novo',

                        style:
                            GoogleFonts
                                .poppins(),
                      ),

                      value: _isNovo,

                      onChanged: (
                        val,
                      ) {

                        setState(() {

                          _isNovo =
                              val;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    SizedBox(

                      height: 58,

                      child: ElevatedButton(

                        style:
                            ElevatedButton
                                .styleFrom(

                          elevation: 0,

                          backgroundColor:
                              const Color(
                            0xFF0A8449,
                          ),

                          shape:
                              RoundedRectangleBorder(

                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),
                        ),

                        onPressed:
                            carregando

                                ? null

                                : _salvarDoacao,

                        child:
                            carregando

                                ? const SizedBox(

                                    width:
                                        24,

                                    height:
                                        24,

                                    child:
                                        CircularProgressIndicator(

                                      color:
                                          Colors.white,

                                      strokeWidth:
                                          2.5,
                                    ),
                                  )

                                : Text(

                                    'Salvar Doação',

                                    style:
                                        GoogleFonts.poppins(

                                      fontSize:
                                          16,

                                      fontWeight:
                                          FontWeight.w600,

                                      color:
                                          Colors.white,
                                    ),
                                  ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            if (_doacoes.isNotEmpty)

              Text(

                'Doações cadastradas',

                style:
                    GoogleFonts.poppins(

                  fontSize: 20,

                  fontWeight:
                      FontWeight.w700,
                ),
              ),

            const SizedBox(
              height: 18,
            ),

            ..._doacoes.map(

              (doacao) {

                return DoacaoCard(
                  doacao: doacao,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}