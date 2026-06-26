import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/conquista.dart';
import '../services/conquista_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';

class ConquistasScreen extends StatefulWidget {
  const ConquistasScreen({super.key});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen> {
  final ConquistaService _service = ConquistaService();
  List<Conquista> _conquistas = [];
  bool _carregando = true;
  bool _semSessao = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _semSessao = false;
    });
    final usuario = await SessionService().obterUsuario();
    if (!mounted) return;
    final usuarioId = usuario?.id;
    if (usuarioId == null) {
      setState(() {
        _semSessao = true;
        _carregando = false;
      });
      return;
    }
    try {
      final lista = await _service.doador(usuarioId);
      if (!mounted) return;
      setState(() {
        _conquistas = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  IconData _iconePara(String chave) {
    switch (chave) {
      case 'PRIMEIRA_DOACAO':
        return Icons.volunteer_activism;
      case 'DOADOR_RECORRENTE':
        return Icons.repeat;
      case 'CINCO_DOACOES':
        return Icons.filter_5;
      case 'DEZ_DOACOES':
        return Icons.military_tech;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _conquistas.length;
    final desbloqueadas = _conquistas.where((c) => c.conquistada).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conquistas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _semSessao
              ? _vazio(
                  icone: Icons.lock_outline,
                  mensagem: 'Faça login para ver suas conquistas',
                )
              : _conquistas.isEmpty
                  ? _vazio(
                      icone: Icons.emoji_events_outlined,
                      mensagem: 'Nenhuma conquista disponível',
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          _contador(desbloqueadas, total),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _conquistas.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemBuilder: (_, i) => _card(_conquistas[i]),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _contador(int desbloqueadas, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            '$desbloqueadas de $total conquistadas',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Conquista c) {
    final conquistada = c.conquistada;
    final corIcone = conquistada ? AppColors.primary : Colors.grey.shade400;
    final corFundoIcone = conquistada
        ? AppColors.primary.withValues(alpha: 0.12)
        : Colors.grey.shade200;
    final corTitulo = conquistada ? AppColors.textPrimary : Colors.grey.shade500;
    final corDescricao =
        conquistada ? AppColors.textSecondary : Colors.grey.shade400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: corFundoIcone,
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconePara(c.chave), color: corIcone, size: 32),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    conquistada ? Icons.check_circle : Icons.lock_outline,
                    size: 18,
                    color: conquistada ? AppColors.primary : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.titulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: corTitulo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c.descricao,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.3,
              color: corDescricao,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vazio({required IconData icone, required String mensagem}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 80, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            mensagem,
            style: GoogleFonts.poppins(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
