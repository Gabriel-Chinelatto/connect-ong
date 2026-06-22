import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_application_1/ong.dart';
import 'package:flutter_application_1/services/api_service.dart';

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

  bool carregando = true;

  static const String _baseUrl = '${ApiService.baseUrl}/ongs';

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

          carregando = false;
        });
      } else {
        setState(() {
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,

          backgroundColor: Colors.red.shade400,

          content: Text("Erro ao conectar API", style: GoogleFonts.poppins()),
        ),
      );
    }
  }

  void _buscarOng() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _resultados =
          _ongs.where((ong) {
            return ong.nome.toLowerCase().contains(query) ||
                ong.cidade.toLowerCase().contains(query);
          }).toList();
    });
  }

  Widget _buildOngCard(Ong ong) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(26),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),

            blurRadius: 18,

            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(22),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: const Color(0xFF0A8449).withOpacity(0.12),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: const Icon(
                    Icons.volunteer_activism,

                    color: Color(0xFF0A8449),

                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        ong.nome,

                        style: GoogleFonts.poppins(
                          fontSize: 20,

                          fontWeight: FontWeight.w700,

                          color: const Color(0xFF222222),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,

                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xFF0A8449).withOpacity(0.1),

                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Text(
                          "ONG Parceira",

                          style: GoogleFonts.poppins(
                            fontSize: 12,

                            color: const Color(0xFF0A8449),

                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildInfoTile(Icons.email_outlined, ong.email),

                      _buildInfoTile(Icons.phone_outlined, ong.telefone),

                      _buildInfoTile(Icons.location_city_outlined, ong.cidade),

                      const SizedBox(height: 18),

                      Text(
                        'Descrição',

                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,

                          fontSize: 15,

                          color: const Color(0xFF0A8449),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        ong.descricao,

                        style: GoogleFonts.poppins(
                          fontSize: 14,

                          height: 1.5,

                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A8449),

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(vertical: 14),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Em breve você poderá doar para ${ong.nome}',
                                ),
                              ),
                            );
                          },

                          icon: const Icon(Icons.favorite_border),

                          label: const Text("Quero Doar"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0A8449)),

          const SizedBox(width: 10),

          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        elevation: 0,

        backgroundColor: Colors.transparent,

        foregroundColor: Colors.white,

        centerTitle: true,

        title: Text(
          "Buscar Receptor",

          style: GoogleFonts.poppins(
            color: Colors.white,

            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A8449), Color(0xFF066537)],

            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [
                const SizedBox(height: 10),

                Text(
                  "Encontre uma ONG",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Busque instituições para realizar doações",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: "Buscar ONG por nome ou cidade",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF0A8449),
                      ),
                      suffixIcon: IconButton(
                        onPressed: _buscarOng,
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF0A8449),
                        ),
                      ),
                    ),
                    onChanged: (_) => _buscarOng(),
                  ),
                ),

                const SizedBox(height: 18),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "${_resultados.length} ONGs encontradas",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child:
                      carregando
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : _resultados.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Nenhuma ONG encontrada",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _resultados.length,
                            itemBuilder: (context, index) {
                              return _buildOngCard(_resultados[index]);
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
