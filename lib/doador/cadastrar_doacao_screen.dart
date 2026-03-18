import 'package:flutter/material.dart';
import 'package:flutter_application_1/doacao.dart';
import 'doacao_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CadastrarDoacaoScreen extends StatefulWidget {
  const CadastrarDoacaoScreen({super.key});

  @override
  State<CadastrarDoacaoScreen> createState() => _CadastrarDoacaoScreenState();
}

class _CadastrarDoacaoScreenState extends State<CadastrarDoacaoScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _nomeDoacao;
  String? _descricaoDoacao;
  int? _quantidade;

  String? _tipoDoacao;
  List<String> _categorias = ['Alimento', 'Roupa', 'Brinquedo', 'Móvel'];
  String? _categoriaSelecionada;

  bool _isUrgente = false;
  bool _isNovo = false;

  final List<Doacao> _doacoes = [];

  // URL da API
  static const String _baseUrl = 'http://localhost:8080/doacoes';

  Future<void> _salvarDoacaoAPI() async {

    final body = {
      "nome": _nomeDoacao,
      "descricao": _descricaoDoacao,
      "quantidade": _quantidade,
      "categoria": _categoriaSelecionada,
      "tipo": _tipoDoacao,
      "urgente": _isUrgente,
      "novo": _isNovo
    };

    try {

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doação salva no banco")),
        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ${response.statusCode}")),
        );

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro de conexão: $e")),
      );

    }

  }

  void _salvarDoacao() {

    final isValid = _formKey.currentState?.validate() ?? false;
    final tipoValido = _tipoDoacao != null;

    if (!isValid || !tipoValido) {
      setState(() {});
      return;
    }

    _formKey.currentState?.save();

    // salva no banco
    _salvarDoacaoAPI();

    // salva localmente na lista
    setState(() {

      _doacoes.insert(
        0,
        Doacao(
          nome: _nomeDoacao!,
          descricao: _descricaoDoacao!,
          quantidade: _quantidade!,
          categoria: _categoriaSelecionada!,
          tipo: _tipoDoacao!,
          urgente: _isUrgente,
          novo: _isNovo,
        ),
      );

      _formKey.currentState?.reset();
      _tipoDoacao = null;
      _categoriaSelecionada = null;
      _isUrgente = false;
      _isNovo = false;

    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Doação')),
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
                          decoration: const InputDecoration(
                            labelText: 'Nome da Doação',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (val) => _nomeDoacao = val,
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Informe o nome da doação'
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          onSaved: (val) => _descricaoDoacao = val,
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                                  ? 'Informe uma descrição'
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Quantidade',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onSaved: (val) => _quantidade = int.tryParse(val ?? ''),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty)
                              return 'Informe a quantidade';

                            final n = int.tryParse(val);

                            return (n == null || n <= 0)
                                ? 'Quantidade deve ser número positivo'
                                : null;
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          value: _categoriaSelecionada,
                          items: _categorias.map((categoria) {
                            return DropdownMenuItem<String>(
                              value: categoria,
                              child: Text(categoria),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _categoriaSelecionada = val),
                          validator: (val) =>
                              val == null ? 'Selecione uma categoria' : null,
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Tipo de Doação',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        Column(
                          children: ['Nova', 'Usada'].map((tipo) {
                            return RadioListTile<String>(
                              title: Text(tipo),
                              value: tipo,
                              groupValue: _tipoDoacao,
                              onChanged: (val) =>
                                  setState(() => _tipoDoacao = val),
                            );
                          }).toList(),
                        ),

                        if (_tipoDoacao == null)
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              'Selecione o tipo de doação',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        CheckboxListTile(
                          title: const Text('É urgente?'),
                          value: _isUrgente,
                          onChanged: (val) =>
                              setState(() => _isUrgente = val ?? false),
                        ),

                        CheckboxListTile(
                          title: const Text('Produto novo?'),
                          value: _isNovo,
                          onChanged: (val) =>
                              setState(() => _isNovo = val ?? false),
                        ),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A8449),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _salvarDoacao,
                          child: const Text(
                            'Salvar Doação',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (_doacoes.isNotEmpty)
                    const Text(
                      'Doações cadastradas:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),

                  ..._doacoes
                      .map((doacao) => DoacaoCard(doacao: doacao))
                      .toList(),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}