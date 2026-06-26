import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/campanha.dart';
import '../services/campanha_service.dart';
import '../services/favorito_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';

/// Lista as campanhas ativas das ONGs que o doador pode apoiar, com opcao de
/// favoritar cada campanha (persistido por usuario via FavoritoService).
class CampanhasScreen extends StatefulWidget {
  const CampanhasScreen({super.key});

  @override
  State<CampanhasScreen> createState() => _CampanhasScreenState();
}

class _CampanhasScreenState extends State<CampanhasScreen> {
  final CampanhaService _service = CampanhaService();
  final FavoritoService _favService = FavoritoService();
  List<Campanha> _campanhas = [];
  bool _carregando = true;
  String? _meuNome;
  int? _usuarioId;
  Set<int> _favCampanhas = {};

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
    _carregar();
  }

  Future<void> _carregarUsuario() async {
    final u = await SessionService().obterUsuario();
    if (!mounted) return;
    _meuNome = u?.nome;
    _usuarioId = u?.id;
    if (_usuarioId == null) return;
    try {
      final favs = await _favService.ids(_usuarioId!, 'CAMPANHA');
      if (!mounted) return;
      setState(() => _favCampanhas = favs);
    } catch (_) {
      // segue sem coracao preenchido
    }
  }

  Future<void> _toggleFavorito(Campanha c) async {
    if (_usuarioId == null) return;
    final jaFavorito = _favCampanhas.contains(c.id);
    try {
      if (jaFavorito) {
        await _favService.remover(_usuarioId!, 'CAMPANHA', c.id);
        if (!mounted) return;
        setState(() => _favCampanhas.remove(c.id));
      } else {
        await _favService.adicionar(_usuarioId!, 'CAMPANHA', c.id);
        if (!mounted) return;
        setState(() => _favCampanhas.add(c.id));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade400,
          content: Text('Erro ao atualizar favorito'),
        ),
      );
    }
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await _service.listarAbertas();
      if (!mounted) return;
      setState(() {
        _campanhas = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  Future<void> _contribuir(Campanha c) async {
    final controller = TextEditingController();
    final valor = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contribuir com "${c.titulo}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [10, 25, 50, 100]
                  .map((v) => ActionChip(
                        label: Text('R\$ $v'),
                        onPressed: () => controller.text = v.toString(),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              Navigator.pop(ctx, v);
            },
            child: const Text('Contribuir'),
          ),
        ],
      ),
    );

    // Descarta o controller apos o dialogo fechar (evita vazamento).
    controller.dispose();

    if (valor == null || valor <= 0) return;
    try {
      final atualizada = await _service.contribuir(
        campanhaId: c.id,
        valor: valor,
        doadorNome: _meuNome,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(atualizada.encerrada
              ? 'Obrigado! A campanha atingiu a meta! 🎉'
              : 'Obrigado pela contribuição de R\$ ${valor.toStringAsFixed(2)}!'),
        ),
      );
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade400,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campanhas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _campanhas.isEmpty
              ? _vazio()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _campanhas.length,
                    itemBuilder: (_, i) => _card(_campanhas[i]),
                  ),
                ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined,
              size: 80, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Nenhuma campanha ativa no momento',
              style: GoogleFonts.poppins(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _card(Campanha c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (c.destaque)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('Destaque',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800)),
                    ],
                  ),
                ),
              Expanded(
                child: Text(
                  c.titulo,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (_usuarioId != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _favCampanhas.contains(c.id)
                      ? 'Remover dos favoritos'
                      : 'Favoritar',
                  onPressed: () => _toggleFavorito(c),
                  icon: Icon(
                    _favCampanhas.contains(c.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          if (c.ongNome != null) ...[
            const SizedBox(height: 2),
            Text(c.ongNome!,
                style:
                    GoogleFonts.poppins(fontSize: 13, color: AppColors.primary)),
          ],
          const SizedBox(height: 10),
          Text(c.descricao,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: c.progresso / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('R\$ ${c.valorArrecadado.toStringAsFixed(0)} de '
                  'R\$ ${c.metaValor.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${c.progresso}%',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _contribuir(c),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.favorite),
              label: const Text('Contribuir'),
            ),
          ),
        ],
      ),
    );
  }
}
