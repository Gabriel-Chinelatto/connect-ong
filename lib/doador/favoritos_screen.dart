import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/favorito.dart';
import '../services/favorito_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import 'perfil_publico_ong_screen.dart';

/// Tela com os favoritos do doador (ONGs e campanhas).
class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final FavoritoService _service = FavoritoService();
  List<Favorito> _favoritos = [];
  bool _carregando = true;
  int? _usuarioId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final u = await SessionService().obterUsuario();
    if (!mounted) return;
    _usuarioId = u?.id;
    if (_usuarioId == null) {
      setState(() => _carregando = false);
      return;
    }
    try {
      final lista = await _service.listar(_usuarioId!);
      if (!mounted) return;
      setState(() {
        _favoritos = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _remover(Favorito f) async {
    if (_usuarioId == null) return;
    try {
      await _service.remover(_usuarioId!, f.tipo, f.alvoId);
      if (!mounted) return;
      setState(() => _favoritos.remove(f));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade400,
          content: Text('Erro ao remover favorito',
              style: GoogleFonts.poppins()),
        ),
      );
    }
  }

  void _abrir(Favorito f) {
    if (f.tipo == 'ONG') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PerfilPublicoOngScreen(
            ongId: f.alvoId,
            ongNome: f.alvoNome,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _usuarioId == null
              ? _mensagem(Icons.login, 'Faça login para ver seus favoritos')
              : _favoritos.isEmpty
                  ? _mensagem(Icons.favorite_border,
                      'Você ainda não favoritou nada')
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _favoritos.length,
                        separatorBuilder: (_, i) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _item(_favoritos[i]),
                      ),
                    ),
    );
  }

  Widget _mensagem(IconData icon, String texto) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(texto, style: GoogleFonts.poppins(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _item(Favorito f) {
    final bool isOng = f.tipo == 'ONG';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isOng ? Icons.favorite : Icons.campaign,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          f.alvoNome,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isOng ? 'ONG' : 'Campanha',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: AppColors.error),
          tooltip: 'Remover dos favoritos',
          onPressed: () => _remover(f),
        ),
        onTap: () => _abrir(f),
      ),
    );
  }
}
