import 'package:flutter/material.dart';
import 'package:flutter_application_1/ong.dart';
import 'package:flutter_application_1/ong_card.dart';
import 'package:flutter_application_1/receptor/editar_ong_screen.dart';
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

  final List<Ong> _ongs = [];

  // Para Flutter WEB (Chrome)
static const String _baseUrl = 'http://localhost:8080/ongs';

// Para celular físico
// static const String _baseUrl = 'http://192.168.0.27:8080/ongs';

// Para emulador Android
// static const String _baseUrl = 'http://10.0.2.2:8080/ongs';q
  @override
  void initState() {
    super.initState();
    _fetchOngs();
  }

  // ✅ GET
  Future<void> _fetchOngs() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _ongs.clear();
          _ongs.addAll(data.map((json) => Ong.fromJson(json)).toList());
        });
      } else {
        _showSnackBar('Erro ao carregar: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
    }
  }

  // ✅ POST
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

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newOng.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('ONG cadastrada!');

        _formKey.currentState?.reset();
        _nome = _email = _telefone = _cidade = _descricao = null;

        await _fetchOngs(); // 🔥 Atualiza lista
      } else {
        _showSnackBar('Erro ao cadastrar: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
    }
  }

  // ✅ DELETE
  Future<void> _deleteOng(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$id'));

      if (response.statusCode == 204) {
        setState(() {
          _ongs.removeWhere((ong) => ong.id == id);
        });
        _showSnackBar('ONG excluída!');
      } else {
        _showSnackBar('Erro ao excluir: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
    }
  }

  // ✅ EDIT
  void _startEditOng(Ong ong) async {
    final updatedOng = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EditarOngScreen(ong: ong, baseUrl: _baseUrl),
      ),
    );

    if (updatedOng != null && updatedOng is Ong) {
      setState(() {
        final index = _ongs.indexWhere((o) => o.id == updatedOng.id);
        if (index >= 0) {
          _ongs[index] = updatedOng;
        }
      });
      _showSnackBar('Atualizada!');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar ONG')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: _inputDecoration('Nome'),
                          onSaved: (val) => _nome = val,
                          validator: (val) => val == null || val.isEmpty ? 'Informe o nome' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDecoration('Email'),
                          onSaved: (val) => _email = val,
                          validator: (val) => val == null || !val.contains('@') ? 'Email inválido' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDecoration('Telefone'),
                          onSaved: (val) => _telefone = val,
                          validator: (val) => val == null || val.isEmpty ? 'Informe o telefone' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDecoration('Cidade'),
                          onSaved: (val) => _cidade = val,
                          validator: (val) => val == null || val.isEmpty ? 'Informe a cidade' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: _inputDecoration('Descrição'),
                          maxLines: 3,
                          onSaved: (val) => _descricao = val,
                          validator: (val) => val == null || val.isEmpty ? 'Informe a descrição' : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _saveOng,
                          child: const Text('Salvar ONG'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_ongs.isNotEmpty)
                    ..._ongs.map((ong) => OngCard(
                          ong: ong,
                          onEdit: _startEditOng,
                          onDelete: _deleteOng,
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}