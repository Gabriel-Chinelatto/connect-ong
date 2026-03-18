import 'package:flutter/material.dart';
import 'package:flutter_application_1/ong.dart';
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

  // 🔥 URL CORRIGIDA COM SEU IP
  static const String _baseUrl = 'http://192.168.0.27:8080/ongs';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOngs() async {
    final query = _searchController.text.trim();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final url = query.isEmpty
          ? Uri.parse(_baseUrl)
          : Uri.parse('$_baseUrl?nome=$query');

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
        title: Text(ong.nome,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cidade: ${ong.cidade}'),
            Text('Email: ${ong.email}'),
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Nome da ONG ou Cidade',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (_) => _fetchOngs(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _fetchOngs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8449),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Pesquisar ONGs',
                        style:
                            TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: !_hasSearched && !_isLoading
                  ? const Center(
                      child: Text(
                          'Use a barra de busca acima para encontrar ONGs.'),
                    )
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredOngs.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhuma ONG encontrada para "${_searchController.text}"',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _filteredOngs.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                return _buildOngTile(
                                    _filteredOngs[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}