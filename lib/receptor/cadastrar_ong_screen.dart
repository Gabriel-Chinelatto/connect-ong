import 'package:flutter/material.dart';
import 'package:flutter_application_1/ong.dart';
import 'package:flutter_application_1/ong_card.dart';
import 'package:flutter_application_1/receptor/editar_ong_screen.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CadastrarOngScreen extends StatefulWidget {
  const CadastrarOngScreen({super.key});

  @override
  State<CadastrarOngScreen> createState() => _CadastrarOngScreenState();
}

class _CadastrarOngScreenState extends State<CadastrarOngScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _nome;
  String? _email;
  String? _telefone;
  String? _cidade;
  String? _descricao;

  bool _isLoading = false;

  final List<Ong> _ongs = [];

  static const String _baseUrl = '${ApiService.baseUrl}/ongs';

  @override
  void initState() {
    super.initState();
    _fetchOngs();
  }

  // ==========================
  // BUSCAR ONGS
  // ==========================
  Future<void> _fetchOngs() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _ongs.clear();
          _ongs.addAll(
            data.map((json) => Ong.fromJson(json)).toList(),
          );
        });
      } else {
        _showSnackBar(
          'Erro ao carregar ONGs.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Erro de conexão com servidor.',
        isError: true,
      );
    }
  }

  // ==========================
  // SALVAR ONG
  // ==========================
  Future<void> _saveOng() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    _formKey.currentState?.save();

    final newOng = Ong(
      nome: _nome!,
      email: _email!,
      telefone: _telefone!,
      cidade: _cidade!,
      descricao: _descricao!,
    );

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newOng.toJson()),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        _showSnackBar('ONG cadastrada com sucesso.');

        _formKey.currentState?.reset();

        _nome = null;
        _email = null;
        _telefone = null;
        _cidade = null;
        _descricao = null;

        await _fetchOngs();
      } else {
        _showSnackBar(
          'Erro ao cadastrar ONG.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Erro de conexão.',
        isError: true,
      );
    }

    setState(() => _isLoading = false);
  }

  // ==========================
  // EXCLUIR ONG
  // ==========================
  Future<void> _deleteOng(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Deseja realmente excluir esta ONG?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final response =
          await http.delete(Uri.parse('$_baseUrl/$id'));

      if (response.statusCode == 204) {
        setState(() {
          _ongs.removeWhere((ong) => ong.id == id);
        });

        _showSnackBar('ONG excluída.');
      } else {
        _showSnackBar(
          'Erro ao excluir ONG.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Erro de conexão.',
        isError: true,
      );
    }
  }

  // ==========================
  // EDITAR ONG
  // ==========================
  void _startEditOng(Ong ong) async {
    final updatedOng = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditarOngScreen(
          ong: ong,
          baseUrl: _baseUrl,
        ),
      ),
    );

    if (updatedOng != null && updatedOng is Ong) {
      setState(() {
        final index =
            _ongs.indexWhere((o) => o.id == updatedOng.id);

        if (index >= 0) {
          _ongs[index] = updatedOng;
        }
      });

      _showSnackBar('ONG atualizada.');
    }
  }

  // ==========================
  // ALERTAS
  // ==========================
  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? Colors.red : const Color(0xFF0A8449),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ==========================
  // INPUT PADRÃO
  // ==========================
  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ==========================
  // BUILD
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar ONG'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A8449),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // FORM
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration:
                              _inputDecoration(
                                'Nome',
                                Icons.business,
                              ),
                          onSaved: (val) => _nome = val,
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Informe o nome'
                                  : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          keyboardType:
                              TextInputType.emailAddress,
                          decoration:
                              _inputDecoration(
                                'Email',
                                Icons.email,
                              ),
                          onSaved: (val) => _email = val,
                          validator: (val) =>
                              val == null ||
                                      !val.contains('@')
                                  ? 'Email inválido'
                                  : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          keyboardType:
                              TextInputType.phone,
                          decoration:
                              _inputDecoration(
                                'Telefone',
                                Icons.phone,
                              ),
                          onSaved: (val) => _telefone = val,
                          validator: (val) {
                            if (val == null ||
                                val.trim().isEmpty) {
                              return 'Informe o telefone';
                            }

                            final numeros = val.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );

                            if (numeros.length < 10) {
                              return 'Telefone inválido';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          decoration:
                              _inputDecoration(
                                'Cidade',
                                Icons.location_city,
                              ),
                          onSaved: (val) => _cidade = val,
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Informe a cidade'
                                  : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          maxLines: 3,
                          decoration:
                              _inputDecoration(
                                'Descrição',
                                Icons.description,
                              ),
                          onSaved: (val) =>
                              _descricao = val,
                          validator: (val) =>
                              val == null || val.trim().isEmpty
                                  ? 'Informe a descrição'
                                  : null,
                        ),
                        const SizedBox(height: 20),

                        // BOTÃO
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              _isLoading
                                  ? 'Salvando...'
                                  : 'Salvar ONG',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                      0xFF0A8449),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        14),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : _saveOng,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // LISTA
                  if (_ongs.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Nenhuma ONG cadastrada.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  ..._ongs.map(
                    (ong) => OngCard(
                      ong: ong,
                      onEdit: _startEditOng,
                      onDelete: _deleteOng,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}