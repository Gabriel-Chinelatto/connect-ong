import 'package:flutter/material.dart';
import 'package:flutter_application_1/ong.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BuscarOngScreen extends StatefulWidget {
  const BuscarOngScreen({super.key});

  @override
  State<BuscarOngScreen> createState() => _BuscarOngScreenState();
}

class _BuscarOngScreenState extends State<BuscarOngScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Lista completa carregada uma vez; o filtro acontece em memória.
  List<Ong> _ongs = [];
  List<Ong> _filteredOngs = [];
  bool _isLoading = true;

  static const String _baseUrl = '${ApiService.baseUrl}/ongs';

  @override
  void initState() {
    super.initState();
    _carregarOngs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Carrega todas as ONGs uma única vez.
  Future<void> _carregarOngs() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _ongs = data.map((json) => Ong.fromJson(json)).toList();
          _filteredOngs = _ongs;
          _isLoading = false;
        });
      } else {
        _showSnackBar('Falha ao buscar ONGs: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e');
      setState(() => _isLoading = false);
    }
  }

  // Filtra a lista já carregada por nome ou cidade, ao vivo.
  void _filtrarOngs(String query) {
    final q = query.toLowerCase().trim();

    setState(() {
      _filteredOngs = _ongs.where((ong) {
        return ong.nome.toLowerCase().contains(q) ||
            ong.cidade.toLowerCase().contains(q);
      }).toList();
    });
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
              onChanged: _filtrarOngs,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
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
                          separatorBuilder: (_, _) => const Divider(),
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
