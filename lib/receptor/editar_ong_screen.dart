import 'package:flutter/material.dart';
import 'package:flutter_application_1/ong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditarOngScreen extends StatefulWidget {
  final Ong ong;
  final String baseUrl;

  const EditarOngScreen({super.key, required this.ong, required this.baseUrl});

  @override
  State<EditarOngScreen> createState() => _EditarOngScreenState();
}

class _EditarOngScreenState extends State<EditarOngScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para pré-preencher e gerenciar os campos de texto
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _cidadeController;
  late TextEditingController _descricaoController;

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores com os dados atuais da ONG
    _nomeController = TextEditingController(text: widget.ong.nome);
    _emailController = TextEditingController(text: widget.ong.email);
    _telefoneController = TextEditingController(text: widget.ong.telefone);
    _cidadeController = TextEditingController(text: widget.ong.cidade);
    _descricaoController = TextEditingController(text: widget.ong.descricao);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cidadeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _updateOng() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final updatedOng = Ong(
      id: widget.ong.id, // O ID deve ser mantido
      nome: _nomeController.text,
      email: _emailController.text,
      telefone: _telefoneController.text,
      cidade: _cidadeController.text,
      descricao: _descricaoController.text,
    );

    try {
      final response = await http.put(
        // Chama o endpoint PUT: /ongs/{id}
        Uri.parse('${widget.baseUrl}/${widget.ong.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedOng.toJson()),
      );

      if (response.statusCode == 200) {
        // Sucesso: Retorna a ONG atualizada para a tela anterior
        final returnedOng = Ong.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        
        // Navigator.pop envia o objeto de volta para a tela de cadastro
        Navigator.of(context).pop(returnedOng);
      } else {
        _showSnackBar('Falha ao atualizar ONG: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Erro ao conectar com a API: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
      appBar: AppBar(title: Text('Editar ONG: ${widget.ong.nome}')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: _inputDecoration('Nome da ONG'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Informe o nome da ONG' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@') ? 'Informe um email válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: _inputDecoration('Telefone'),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty ? 'Informe o telefone' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cidadeController,
                decoration: _inputDecoration('Cidade'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Informe a cidade' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: _inputDecoration('Descrição da ONG'),
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty ? 'Informe uma descrição' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8449),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _updateOng,
                child: const Text('Salvar Alterações', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}