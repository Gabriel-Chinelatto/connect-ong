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

  // Campos do formulário da ONG
  String? _nome;
  String? _email;
  String? _telefone;
  String? _cidade;
  String? _descricao;
  
  // Lista para armazenar as ONGs cadastradas
  final List<Ong> _ongs = [];
  
  // URL base da sua API
  // LEMBRE-SE de ajustar para o seu IP real (ex: http://10.0.2.2:8080 para emulador Android)
  static const String _baseUrl = 'http://localhost:8080/ongs'; 

  @override
  void initState() {
    super.initState();
    _fetchOngs();
  }

  // Função para buscar ONGs (GET)
  Future<void> _fetchOngs() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/buscar'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _ongs.clear();
          _ongs.addAll(data.map((json) => Ong.fromJson(json)).toList());
        });
      } else {
        _showSnackBar('Falha ao carregar ONGs: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
    }
  }

  // Função para salvar a ONG (POST)
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
        Uri.parse('$_baseUrl/criar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newOng.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final registeredOng = Ong.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        
        setState(() {
          _ongs.insert(0, registeredOng);
          _formKey.currentState?.reset();
          _nome = _email = _telefone = _cidade = _descricao = null;
        });

        _showSnackBar('ONG cadastrada com sucesso!');
      } else {
        _showSnackBar('Falha ao cadastrar ONG: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Erro ao tentar conectar com a API: $e');
    }
  }
  
  // Função para deletar a ONG (DELETE)
  Future<void> _deleteOng(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
      );

      if (response.statusCode == 204) { // 204 No Content é o esperado para DELETE
        setState(() {
          _ongs.removeWhere((ong) => ong.id == id);
        });
        _showSnackBar('ONG excluída com sucesso!');
      } else {
        _showSnackBar('Falha ao excluir ONG: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Erro ao conectar com a API: $e');
    }
  }

  // Função para navegar e editar (chama a tela EditarOngScreen)
  void _startEditOng(Ong ong) async {
    final updatedOng = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EditarOngScreen(ong: ong, baseUrl: _baseUrl),
      ),
    );

    // Verifica se a ONG foi atualizada e retornada
    if (updatedOng != null && updatedOng is Ong) {
      setState(() {
        final index = _ongs.indexWhere((o) => o.id == updatedOng.id);
        if (index >= 0) {
          // Substitui a ONG antiga pela nova atualizada na lista local
          _ongs[index] = updatedOng;
        }
      });
      _showSnackBar('ONG "${updatedOng.nome}" atualizada!');
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                          decoration: _inputDecoration('Nome da ONG'),
                          onSaved: (val) => _nome = val,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Informe o nome da ONG' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: _inputDecoration('Email'),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (val) => _email = val,
                          validator: (val) => val == null || !val.contains('@') ? 'Informe um email válido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: _inputDecoration('Telefone'),
                          keyboardType: TextInputType.phone,
                          onSaved: (val) => _telefone = val,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Informe o telefone' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: _inputDecoration('Cidade'),
                          onSaved: (val) => _cidade = val,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Informe a cidade' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: _inputDecoration('Descrição da ONG'),
                          maxLines: 3,
                          onSaved: (val) => _descricao = val,
                          validator: (val) => val == null || val.trim().isEmpty ? 'Informe uma descrição' : null,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A8449),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _saveOng,
                          child: const Text('Salvar ONG', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_ongs.isNotEmpty) ...[
                    const Text('ONGs cadastradas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    // Lista as ONGs com os callbacks de ação
                    ..._ongs.map((ong) => OngCard(
                      ong: ong,
                      onEdit: _startEditOng, // Passa a função de edição
                      onDelete: _deleteOng, // Passa a função de deleção
                    )).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}