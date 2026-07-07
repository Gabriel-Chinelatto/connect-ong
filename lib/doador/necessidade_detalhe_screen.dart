import 'package:flutter/material.dart';

import '../models/necessidade.dart';
import '../services/api_service.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/page_transition.dart';
import '../utils/tempo.dart';
import '../widgets/cards/capa_categoria.dart';
import '../widgets/feedback/app_snackbar.dart';

import 'perfil_publico_ong_screen.dart';

/// Detalhe de uma NECESSIDADE de ONG: capa da categoria (com selo URGENTE),
/// título grande, ONG clicável (abre o perfil público), descrição completa,
/// cidade, "Postado há X" (oculto quando o backend ainda não envia
/// `dataCriacao`) e o botão grande "Tenho interesse".
///
/// Aberta ao tocar num card das "Necessidades urgentes" da Início ou no corpo
/// de um card do feed Explorar.
///
/// O botão espelha o estado do feed: [jaInteressado] indica interesse EM
/// ANDAMENTO (PENDENTE/ACEITO) → "Interesse demonstrado" (desabilitado);
/// [jaConcluido] indica que houve um interesse CONCLUÍDO e nenhum ativo →
/// disponível de novo com "Demonstrar interesse novamente". Quando o chamador
/// não sabe (ex.: Início), a tela verifica sozinha via GET /interesses?doadorId=
/// (falha degrada para "não"). [onInteresseDemonstrado] avisa o chamador para
/// atualizar o card na volta.
class NecessidadeDetalheScreen extends StatefulWidget {
  final Necessidade necessidade;
  final bool? jaInteressado;
  final bool? jaConcluido;
  final VoidCallback? onInteresseDemonstrado;

  const NecessidadeDetalheScreen({
    super.key,
    required this.necessidade,
    this.jaInteressado,
    this.jaConcluido,
    this.onInteresseDemonstrado,
  });

  @override
  State<NecessidadeDetalheScreen> createState() =>
      _NecessidadeDetalheScreenState();
}

class _NecessidadeDetalheScreenState extends State<NecessidadeDetalheScreen> {
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  int? _doadorId;
  bool _jaInteressado = false; // interesse EM ANDAMENTO (PENDENTE/ACEITO)
  bool _jaConcluido = false; // houve concluído antes e nada ativo agora
  bool _enviando = false; // guarda anti-duplo-toque do POST

  @override
  void initState() {
    super.initState();
    _jaInteressado = widget.jaInteressado ?? false;
    _jaConcluido = widget.jaConcluido ?? false;
    _preparar();
  }

  /// Carrega o doador da sessão e, quando o chamador não informou o estado,
  /// verifica os interesses nesta necessidade: EM ANDAMENTO (PENDENTE/ACEITO)
  /// vs apenas CONCLUÍDO (disponível de novo).
  Future<void> _preparar() async {
    final usuario = await _sessionService.obterUsuario();
    if (!mounted) return;
    setState(() => _doadorId = usuario?.id);

    if (widget.jaInteressado != null || usuario == null) return;
    try {
      final interesses = await _interesseService.meusMatches(usuario.id);
      final desta = interesses
          .where((i) => i.necessidadeId == widget.necessidade.id)
          .toList();
      // Em andamento se algum está PENDENTE/ACEITO; senão, "concluído antes"
      // quando existe um CONCLUÍDO. O backend só permite um ativo por vez.
      final emAndamento = desta
          .any((i) => i.status == 'PENDENTE' || i.status == 'ACEITO');
      final concluido = desta.any((i) => i.status == 'CONCLUIDO');
      if (!mounted) return;
      setState(() {
        _jaInteressado = _jaInteressado || emAndamento;
        _jaConcluido = !emAndamento && concluido;
      });
    } catch (_) {
      // Sem rede/backend antigo: segue como "não demonstrado"; o backend
      // continua sendo a barreira contra duplicados.
    }
  }

  Future<void> _demonstrarInteresse() async {
    if (_doadorId == null) {
      AppSnackbar.erro(context, 'Você precisa estar logado como doador.');
      return;
    }
    if (_enviando || _jaInteressado) return;
    setState(() => _enviando = true);
    try {
      await _interesseService.demonstrarInteresse(
        necessidadeId: widget.necessidade.id,
        doadorId: _doadorId!,
      );
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _jaInteressado = true;
        _jaConcluido = false; // agora há interesse ativo de novo
      });
      widget.onInteresseDemonstrado?.call();
      AppSnackbar.sucesso(context, 'Interesse enviado! A ONG vai avaliar. 💚');
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  void _abrirPerfilOng() {
    final n = widget.necessidade;
    if (n.ongId == null) return;
    Navigator.push(
      context,
      PageTransition.fade(PerfilPublicoOngScreen(
        ongId: n.ongId!,
        ongNome: n.ongNome ?? 'ONG',
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = widget.necessidade;
    final postado = tempoRelativo(n.dataCriacao);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Necessidade'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          // Capa ilustrativa da categoria, com o selo URGENTE sobre ela.
          CapaCategoria(
            categoria: n.categoria,
            altura: 150,
            selo: n.urgente ? _seloUrgente() : null,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.titulo,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _cardOng(n),
                const SizedBox(height: AppSpacing.lg),
                if (n.descricao.trim().isNotEmpty) ...[
                  Text(
                    'Sobre esta necessidade',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    n.descricao,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                // Cidade + "Postado há X" (a linha some quando o backend
                // ainda não envia dataCriacao).
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if ((n.ongCidade ?? '').trim().isNotEmpty)
                      _meta(Icons.location_on_outlined, n.ongCidade!.trim()),
                    if (postado.isNotEmpty)
                      _meta(Icons.schedule, 'Postado $postado'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      // Botão grande fixo embaixo: mesma lógica/guards do feed.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: _botaoInteresse(),
      ),
    );
  }

  // ---- ONG: avatar/inicial + nome + verificada + nota, CLICÁVEL ----
  Widget _cardOng(Necessidade n) {
    final cs = Theme.of(context).colorScheme;
    final nome = (n.ongNome ?? 'ONG').trim();
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
    final clicavel = n.ongId != null;

    return Semantics(
      button: clicavel,
      label: clicavel ? 'Abrir perfil da ONG $nome' : null,
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: clicavel ? _abrirPerfilOng : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (n.ongVerificada) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                size: 16, color: AppColors.primary),
                          ],
                        ],
                      ),
                      if (n.ongTotalAvaliacoes > 0) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 15, color: AppColors.ouro),
                            const SizedBox(width: 2),
                            Text(
                              '${n.ongNotaMedia.toStringAsFixed(1)} '
                              '(${n.ongTotalAvaliacoes} '
                              '${n.ongTotalAvaliacoes == 1 ? "avaliação" : "avaliações"})',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (clicavel)
                  Icon(Icons.chevron_right,
                      size: 22, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icone, String texto) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 15, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          texto,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  // Botão principal, espelhando o estado do feed (enviado/enviando/normal).
  Widget _botaoInteresse() {
    if (_jaInteressado) {
      return FilledButton.tonalIcon(
        onPressed: null,
        icon: const Icon(Icons.check, size: 20),
        label: const Text('Interesse demonstrado'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: _enviando ? null : _demonstrarInteresse,
      icon: _enviando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.favorite, size: 20),
      // "novamente" quando já houve uma doação concluída antes.
      label: Text(_enviando
          ? 'Enviando...'
          : (_jaConcluido
              ? 'Demonstrar interesse novamente'
              : 'Tenho interesse')),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  // Selo sólido (fundo vermelho, texto branco) legível SOBRE a capa colorida.
  Widget _seloUrgente() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.error,
        borderRadius: AppRadius.brSm,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high, size: 13, color: Colors.white),
          SizedBox(width: 2),
          Text('URGENTE',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
        ],
      ),
    );
  }
}
