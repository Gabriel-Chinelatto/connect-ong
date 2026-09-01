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

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Busca de ONGs receptoras: lista e filtra ONGs por nome ou cidade, permite
/// favoritar e abre o perfil publico ou a doacao via PIX. Ponto de partida para
/// o doador escolher uma instituicao para apoiar.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
///
/// CARREGAMENTO AOS POUCOS (rolagem infinita). Esta tela baixava as ONGs TODAS
/// numa chamada so e guardava a lista inteira na memoria. Com 2.000 instituicoes
/// isso travava de dois jeitos: ao abrir, porque criava 2.000 objetos de uma vez
/// na thread da interface; e ao digitar, porque refiltrava as 2.000 a cada tecla.
///
/// Agora a tela pede [_porPagina] por vez e busca a proxima pagina quando o
/// usuario se aproxima do fim da lista. A busca tambem foi para o servidor, com
/// um respiro de [_esperaDigitacao] entre a ultima tecla e a chamada — quem
/// digita "lar viva" gera UMA busca, nao oito.
class BuscarReceptorScreen extends StatefulWidget {
  const BuscarReceptorScreen({super.key});

  @override
  State<BuscarReceptorScreen> createState() => _BuscarReceptorScreenState();
}

class _BuscarReceptorScreenState extends State<BuscarReceptorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Quantas ONGs por pagina. 20 enche mais de uma tela de rolagem, entao a
  /// proxima pagina chega antes de o usuario ver o fim.
  static const int _porPagina = 20;

  /// Respiro entre a ultima tecla e a busca no servidor.
  static const Duration _esperaDigitacao = Duration(milliseconds: 400);

  /// So o que ja foi carregado — nunca as 2.000.
  final List<Ong> _resultados = [];

  int _pagina = 0;
  bool _temMais = true;
  bool carregando = true;
  bool _carregandoMais = false;

  /// Texto que a lista atual representa (nao o que esta digitado agora).
  String _buscaAtual = '';
  Timer? _debounce;

  /// Cresce a cada nova busca. A resposta que chegar com numero antigo e
  /// descartada — sem isso, uma busca lenta sobrescreve o resultado da seguinte.
  int _buscaId = 0;

  final FavoritoService _favService = FavoritoService();
  int? _usuarioId;
  Set<int> _favOngs = {};

  static const String _baseUrl = '${ApiService.baseUrl}/ongs';

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_aoRolar);
    _carregarPagina(reiniciar: true);
    _carregarFavoritos();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_aoRolar);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Pede a proxima pagina quando falta menos de uma tela e meia para o fim.
  void _aoRolar() {
    if (!_scrollController.hasClients) return;
    final faltando = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (faltando < 600) {
      _carregarPagina();
    }
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

  /// Carrega uma pagina. Com [reiniciar], zera a lista e volta para a primeira
  /// (e o que acontece ao abrir a tela e a cada nova busca).
  Future<void> _carregarPagina({bool reiniciar = false}) async {
    if (!reiniciar && (_carregandoMais || !_temMais || carregando)) return;

    final id = reiniciar ? ++_buscaId : _buscaId;
    if (reiniciar) {
      setState(() {
        _pagina = 0;
        _temMais = true;
        carregando = true;
        _resultados.clear();
      });
    } else {
      setState(() => _carregandoMais = true);
    }

    final url = Uri.parse(_baseUrl).replace(queryParameters: {
      'pagina': '$_pagina',
      'tamanho': '$_porPagina',
      if (_buscaAtual.isNotEmpty) 'nome': _buscaAtual,
    });

    try {
      final response = await http
          .get(url, headers: ApiService.authHeaders())
          .timeout(ApiService.timeout);

      // Chegou tarde: uma busca mais nova ja tomou o lugar desta.
      if (!mounted || id != _buscaId) return;

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _resultados.addAll(data.map((e) => Ong.fromJson(e)));
          // Fim da lista e pagina VAZIA, nao pagina menor que o pedido: o
          // servidor filtra ONGs que bloquearam o doador DEPOIS de paginar,
          // entao uma pagina cheia pode chegar aqui com menos itens.
          _temMais = data.isNotEmpty;
          _pagina++;
          carregando = false;
          _carregandoMais = false;
        });
      } else {
        setState(() {
          carregando = false;
          _carregandoMais = false;
        });
      }
    } catch (e) {
      if (!mounted || id != _buscaId) return;
      setState(() {
        carregando = false;
        _carregandoMais = false;
      });
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  /// Chamado a cada tecla: agenda a busca e cancela a anterior.
  void _aoDigitar(String texto) {
    _debounce?.cancel();
    _debounce = Timer(_esperaDigitacao, () => _buscarOng());
  }

  /// Busca no SERVIDOR (nome ou cidade) e recomeca da primeira pagina.
  void _buscarOng() {
    _debounce?.cancel();
    final texto = _searchController.text.trim();
    if (texto == _buscaAtual && _resultados.isNotEmpty) return;
    _buscaAtual = texto;
    _carregarPagina(reiniciar: true);
  }

  /// Rodape da lista: carregando a proxima pagina, ou o fim.
  Widget _rodapeDaLista() {
    if (_carregandoMais) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
          ),
        ),
      );
    }
    if (!_temMais && _resultados.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 28),
        child: Center(
          child: Text(
            _resultados.length == 1
                ? '1 instituição encontrada'
                : '${_resultados.length} instituições encontradas',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 12);
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
                      hintStyle:
                          const TextStyle(color: AppColors.textTertiary),
                      // O container ao redor ja e branco: sem preenchimento do
                      // tema (que no modo escuro pintaria o campo de cinza).
                      filled: false,
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
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscarOng(),
                    onChanged: _aoDigitar,
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
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            // +1 pelo rodape: girinho enquanto a proxima pagina
                            // vem, ou o aviso de que a lista acabou.
                            itemCount: _resultados.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _resultados.length) {
                                return _rodapeDaLista();
                              }
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
