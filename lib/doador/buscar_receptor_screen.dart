import 'package:flutter/material.dart';

import 'package:flutter_application_1/ong.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/services/favorito_service.dart';
import 'package:flutter_application_1/services/session_service.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/theme/app_radius.dart';
import 'package:flutter_application_1/widgets/feedback/app_snackbar.dart';
import 'package:flutter_application_1/doador/doar_pix_screen.dart';
import 'package:flutter_application_1/doador/perfil_publico_ong_screen.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Busca de ONGs receptoras: lista e filtra ONGs por nome, permite favoritar
/// e abre o perfil publico ou a doacao via PIX. Ponto de partida para o doador
/// escolher uma instituicao para apoiar.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
/// A logica de rede (chamadas http diretas) foi preservada intacta.
class BuscarReceptorScreen extends StatefulWidget {
  const BuscarReceptorScreen({super.key});

  @override
  State<BuscarReceptorScreen> createState() => _BuscarReceptorScreenState();
}

class _BuscarReceptorScreenState extends State<BuscarReceptorScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Ong> _ongs = [];

  List<Ong> _resultados = [];

  bool carregando = true;

  final FavoritoService _favService = FavoritoService();
  int? _usuarioId;
  Set<int> _favOngs = {};

  static const String _baseUrl = '${ApiService.baseUrl}/ongs';

  @override
  void initState() {
    super.initState();

    _carregarOngs();
    _carregarFavoritos();
  }

  Future<void> _carregarFavoritos() async {
    final u = await SessionService().obterUsuario();
    if (!mounted) return;
    _usuarioId = u?.id;
    if (_usuarioId == null) return;
    try {
      final favs = await _favService.ids(_usuarioId!, 'ONG');
      if (!mounted) return;
      setState(() => _favOngs = favs);
    } catch (_) {
      // sem favoritos disponiveis; segue sem coracao preenchido
    }
  }

  Future<void> _toggleFavorito(Ong ong) async {
    if (_usuarioId == null || ong.id == null) return;
    final id = ong.id!;
    final jaFavorito = _favOngs.contains(id);
    try {
      if (jaFavorito) {
        await _favService.remover(_usuarioId!, 'ONG', id);
        if (!mounted) return;
        setState(() => _favOngs.remove(id));
      } else {
        await _favService.adicionar(_usuarioId!, 'ONG', id);
        if (!mounted) return;
        setState(() => _favOngs.add(id));
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.erro(context, 'Erro ao atualizar favorito');
    }
  }

  Future<void> _carregarOngs() async {
    try {
      final response =
          await http.get(Uri.parse(_baseUrl), headers: ApiService.authHeaders())
              .timeout(ApiService.timeout);

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
      if (!mounted) return;
      setState(() {
        carregando = false;
      });

      AppSnackbar.erro(context, 'Erro ao conectar API');
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      decoration: BoxDecoration(
        color: cs.surface,

        borderRadius: AppRadius.brLg,

        border: Border.all(color: cs.outlineVariant),
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
                    color: AppColors.primary.withValues(alpha: 0.12),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: const Icon(
                    Icons.volunteer_activism,

                    color: AppColors.primary,

                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ong.nome,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          if (_usuarioId != null && ong.id != null)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: _favOngs.contains(ong.id)
                                  ? 'Remover dos favoritos'
                                  : 'Favoritar',
                              onPressed: () => _toggleFavorito(ong),
                              icon: Icon(
                                _favOngs.contains(ong.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: AppColors.error,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,

                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 0.1),

                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ong.verificada) ...[
                              const Icon(Icons.verified,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              ong.verificada
                                  ? "ONG Verificada"
                                  : "ONG Parceira",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildInfoTile(Icons.email_outlined, ong.email),

                      _buildInfoTile(Icons.phone_outlined, ong.telefone),

                      _buildInfoTile(Icons.location_city_outlined, ong.cidade),

                      const SizedBox(height: 18),

                      Text(
                        'Descrição',

                        style: TextStyle(
                          fontWeight: FontWeight.w600,

                          fontSize: 15,

                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        ong.descricao,

                        style: TextStyle(
                          fontSize: 14,

                          height: 1.5,

                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            if (ong.id == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PerfilPublicoOngScreen(
                                  ongId: ong.id!,
                                  ongNome: ong.nome,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.account_balance_outlined),
                          label: const Text("Ver perfil"),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(vertical: 14),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),

                          onPressed: () {
                            if (ong.id == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoarPixScreen(
                                  ongId: ong.id!,
                                  ongNome: ong.nome,
                                ),
                              ),
                            );
                          },

                          icon: const Icon(Icons.pix),

                          label: const Text("Doar via PIX"),
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),

          const SizedBox(width: 10),

          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 14, color: cs.onSurface))),
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

          style: TextStyle(
            color: Colors.white,

            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Container(
        // Hero da marca: gradiente verde (funciona no claro e no escuro).
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],

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
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Busque instituições para realizar doações",
                  style: TextStyle(
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
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    // A caixa de busca e branca (sobre o hero verde); texto escuro.
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Buscar ONG por nome ou cidade",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Buscar',
                        onPressed: _buscarOng,
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: AppColors.primary,
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
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "${_resultados.length} ONGs encontradas",
                      style: TextStyle(
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
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Nenhuma ONG encontrada",
                                  style: TextStyle(
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
