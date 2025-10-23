import 'package:flutter/material.dart';
import 'package:flutter_application_1/ong.dart'; // Certifique-se de importar sua classe Ong
import 'dart:convert';
import 'package:http/http.dart' as http;

class BuscarOngScreen extends StatefulWidget {
  const BuscarOngScreen({super.key});

  @override
  State<BuscarOngScreen> createState() => _BuscarOngScreenState();
}

class _BuscarOngScreenState extends State<BuscarOngScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Ong> _filteredOngs = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // URL base da sua API
  // LEMBRE-SE de ajustar para o seu IP correto
  static const String _baseUrl = 'http://localhost:8080/ongs'; 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Função para buscar ONGs na API (GET)
  Future<void> _fetchOngs() async {
    final query = _searchController.text.trim();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Endpoint que busca todas ou permite filtrar por nome na API (assumindo que sua API suporta)
      // Se sua API não suporta filtro, busque todas e filtre localmente
      final url = query.isEmpty 
          ? Uri.parse('$_baseUrl/buscar')
          : Uri.parse('$_baseUrl/buscar?nome=$query'); // Exemplo de busca por nome (ajuste conforme sua API)

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        setState(() {
          _filteredOngs.clear();
          _filteredOngs.addAll(data.map((json) => Ong.fromJson(json)).toList());
        });
      } else {
        _showSnackBar('Falha ao buscar ONGs: ${response.statusCode}');
        setState(() => _filteredOngs.clear());
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
      setState(() => _filteredOngs.clear());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
  
  Widget _buildOngTile(Ong ong) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF0A8449),
          child: Icon(Icons.handshake, color: Colors.white),
        ),
        title: Text(ong.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cidade: ${ong.cidade}'),
            Text('Email: ${ong.email}'),
            // Text('Descrição: ${ong.descricao}', maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar ONG'),
        backgroundColor: const Color(0xFF0A8449),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Campo de Busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Nome da ONG ou Cidade',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (_) => _fetchOngs(), // Permite buscar ao pressionar Enter
            ),
            const SizedBox(height: 12),
            // Botão de Pesquisa
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _fetchOngs, // Chama a função que busca na API
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8449),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Pesquisar ONGs', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            
            // Resultados da Busca
            Expanded(
              child: !_hasSearched && !_isLoading
                  ? const Center(
                      child: Text('Use a barra de busca acima para encontrar ONGs.'),
                    )
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredOngs.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhuma ONG encontrada para "${_searchController.text}"',
                                style: const TextStyle(fontSize: 18, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredOngs.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                return _buildOngTile(_filteredOngs[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}