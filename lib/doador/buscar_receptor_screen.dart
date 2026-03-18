import 'package:flutter/material.dart';
import 'package:flutter_application_1/ong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BuscarReceptorScreen extends StatefulWidget {
  const BuscarReceptorScreen({Key? key}) : super(key: key);

  @override
  State<BuscarReceptorScreen> createState() => _BuscarReceptorScreenState();
}

class _BuscarReceptorScreenState extends State<BuscarReceptorScreen> {

  final TextEditingController _searchController = TextEditingController();

  List<Ong> _ongs = [];
  List<Ong> _resultados = [];

  // URL da API
  static const String _baseUrl = 'http://localhost:8080/ongs';

  @override
  void initState() {
    super.initState();
    _carregarOngs();
  }

  Future<void> _carregarOngs() async {

    try {

      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {

        final List data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {

          _ongs = data.map((e) => Ong.fromJson(e)).toList();
          _resultados = _ongs;

        });

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao conectar API: $e")),
      );

    }

  }

  void _buscarOng() {

    final query = _searchController.text.toLowerCase();

    setState(() {

      _resultados = _ongs.where((ong) {

        return ong.nome.toLowerCase().contains(query) ||
               ong.cidade.toLowerCase().contains(query);

      }).toList();

    });

  }

  Widget _buildOngCard(Ong ong) {

    return Card(

      margin: const EdgeInsets.symmetric(vertical: 8),

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(
              ong.nome,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A8449)),
            ),

            const SizedBox(height: 8),

            Text("Email: ${ong.email}"),
            Text("Telefone: ${ong.telefone}"),
            Text("Cidade: ${ong.cidade}"),

            const SizedBox(height: 8),

            Text("Descrição: ${ong.descricao}")

          ],

        ),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text("Buscar Receptor")),

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            TextField(

              controller: _searchController,

              decoration: InputDecoration(

                labelText: "Nome ou cidade da ONG",

                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),

                prefixIcon: const Icon(Icons.search),

              ),

            ),

            const SizedBox(height: 12),

            ElevatedButton(

              onPressed: _buscarOng,

              style: ElevatedButton.styleFrom(

                backgroundColor: const Color(0xFF0A8449),

                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),

                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),

              ),

              child: const Text("Pesquisar"),

            ),

            const SizedBox(height: 20),

            Expanded(

              child: _resultados.isEmpty

                  ? const Center(
                      child: Text("Nenhuma ONG encontrada"))
                  : ListView.builder(

                      itemCount: _resultados.length,

                      itemBuilder: (context, index) {

                        return _buildOngCard(_resultados[index]);

                      },

                    ),

            ),

          ],

        ),

      ),

    );

  }

}