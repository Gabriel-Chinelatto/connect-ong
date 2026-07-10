import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/perfil_publico_doador.dart';
import '../services/perfil_publico_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../utils/tempo.dart';
import '../widgets/feedback/empty_state.dart';
import 'perfil_publico_ong_screen.dart';

/// Página PÚBLICA de um doador — visual espelhado no perfil público da ONG:
/// header verde com foto/inicial, nome, cidade, estrelas da média e "Membro
/// desde `mês/ano`"; badge "Doador 5 estrelas" quando merecido; stats
/// (matches concluídos, doações PIX); "O que as ONGs dizem" (avaliações) e
/// "Prestações de contas recebidas".
///
/// Campos ausentes em contas antigas (membroDesde, foto…) são simplesmente
/// omitidos — a tela nunca quebra por dado null.
class PerfilPublicoDoadorScreen extends StatefulWidget {
  final int usuarioId;

  const PerfilPublicoDoadorScreen({super.key, required this.usuarioId});

  @override
  State<PerfilPublicoDoadorScreen> createState() =>
      _PerfilPublicoDoadorScreenState();
}

class _PerfilPublicoDoadorScreenState extends State<PerfilPublicoDoadorScreen> {
  final PerfilPublicoService _service = PerfilPublicoService();

  PerfilPublicoDoador? _perfil;
  Uint8List? _fotoBytes; // foto decodificada UMA vez (evita decode por frame)
  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final p = await _service.buscarDoador(widget.usuarioId);
      Uint8List? foto;
      if (p.fotoBase64.isNotEmpty) {
        try {
          foto = base64Decode(p.fotoBase64);
        } catch (_) {
          foto = null; // base64 corrompido: cai para a inicial
        }
      }
      if (!mounted) return;
      setState(() {
        _perfil = p;
        _fotoBytes = foto;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_perfil?.nome ?? 'Perfil do doador'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro || _perfil == null
              ? EmptyState(
                  icone: Icons.person_off_outlined,
                  mensagem: 'Não foi possível carregar o perfil',
                  acaoRotulo: 'Tentar de novo',
                  onAcao: _carregar,
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _cabecalho(_perfil!),
                      _statsRow(_perfil!),
                      if (_perfil!.temContato) _secaoContato(_perfil!),
                      if (_perfil!.avaliacoes.isNotEmpty)
                        _secaoAvaliacoes(_perfil!),
                      if (_perfil!.prestacoesRecebidas.isNotEmpty)
                        _secaoPrestacoes(_perfil!),
                      if (_perfil!.avaliacoes.isEmpty &&
                          _perfil!.prestacoesRecebidas.isEmpty)
                        _semHistorico(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  // ---------- Header verde (mesma linguagem do perfil da ONG) ----------
  Widget _cabecalho(PerfilPublicoDoador p) {
    final inicial = p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?';
    final local = [
      if (p.cidade.trim().isNotEmpty) p.cidade.trim(),
      if (p.estado.trim().isNotEmpty) p.estado.trim(),
    ].join(' - ');

    DateTime? desde;
    if (p.membroDesde != null && p.membroDesde!.isNotEmpty) {
      desde = DateTime.tryParse(p.membroDesde!);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: _fotoBytes != null
                  ? DecorationImage(
                      image: MemoryImage(_fotoBytes!), fit: BoxFit.cover)
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            alignment: Alignment.center,
            child: _fotoBytes == null
                ? Text(inicial,
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary))
                : null,
          ),
          const SizedBox(height: 14),
          Text(p.nome,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          if (local.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(local,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _estrelas(p.notaMediaDoador, p.totalAvaliacoesDoador),
          if (desde != null) ...[
            const SizedBox(height: 6),
            Text(
              'Membro desde ${mesAnoPorExtenso(desde)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (p.doadorCincoEstrelas) ...[
            const SizedBox(height: 10),
            _badgeCincoEstrelas(),
          ],
        ],
      ),
    );
  }

  // Badge dourado "Doador 5 estrelas" (média >= 4.8 e >= 1 avaliação).
  Widget _badgeCincoEstrelas() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: AppColors.ouro, size: 18),
          SizedBox(width: 6),
          Text(
            'Doador 5 estrelas',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _estrelas(double nota, int total) {
    final cheias = nota.round().clamp(0, 5);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 5; i++)
          Icon(i < cheias ? Icons.star : Icons.star_border,
              color: AppColors.ouro, size: 20),
        const SizedBox(width: 8),
        Text(
          total > 0
              ? '${nota.toStringAsFixed(1)} ($total)'
              : 'Sem avaliações ainda',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  // ---------- Stats: matches concluídos + doações PIX ----------
  Widget _statsRow(PerfilPublicoDoador p) {
    final cs = Theme.of(context).colorScheme;
    Widget item(IconData icon, int valor, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 6),
              Text('$valor',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: cs.onSurface)),
              Text(label,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          item(Icons.verified_outlined, p.matchesConcluidos,
              'Matches concluídos'),
          item(Icons.pix, p.totalDoacoesPix, 'Doações PIX'),
        ],
      ),
    );
  }

  // ---------- Cartão de seção genérico (mesmo padrão do perfil da ONG) ----------
  Widget _secao(String titulo, IconData icon, List<Widget> filhos) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(titulo,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: cs.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...filhos,
        ],
      ),
    );
  }

  // ---------- Contato público (só quando o doador liberou nos toggles) ----------
  Widget _secaoContato(PerfilPublicoDoador p) {
    final cs = Theme.of(context).colorScheme;
    Widget linha(IconData icon, String valor) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText(
                  valor,
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                ),
              ),
            ],
          ),
        );
    return _secao('Contato', Icons.contact_mail_outlined, [
      if (p.telefone != null && p.telefone!.isNotEmpty)
        linha(Icons.phone_outlined, p.telefone!),
      if (p.email != null && p.email!.isNotEmpty)
        linha(Icons.email_outlined, p.email!),
    ]);
  }

  Widget _secaoAvaliacoes(PerfilPublicoDoador p) {
    final cs = Theme.of(context).colorScheme;
    return _secao('O que as ONGs dizem', Icons.forum_outlined, [
      // Selo de confianca: a reputacao tem lastro (o backend so aceita avaliacao
      // de uma ONG que concluiu uma doacao com este doador).
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(Icons.verified_user_outlined,
                size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Só ONGs que concluíram uma doação com este doador podem avaliar.',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
      for (final a in p.avaliacoes)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(a.ongNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                  ),
                  for (int i = 0; i < 5; i++)
                    Icon(i < a.nota ? Icons.star : Icons.star_border,
                        size: 14, color: AppColors.ouro),
                ],
              ),
              if (a.comentario != null && a.comentario!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(a.comentario!,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.4)),
              ],
              // Fotos da doação recebida que a ONG anexou à avaliação.
              if (a.fotos.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final b64 in a.fotos) _fotoAvaliacao(b64)],
                ),
              ],
              if (dataCurtaDeIso(a.criadoEm).isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(dataCurtaDeIso(a.criadoEm),
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ],
          ),
        ),
    ]);
  }

  // Miniatura de uma foto (base64) anexada pela ONG à avaliação; toca para
  // ampliar. base64 inválido é ignorado (não quebra a lista).
  Widget _fotoAvaliacao(String b64) {
    final Uint8List bytes;
    try {
      bytes = base64Decode(b64);
    } catch (_) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes,
            width: 64, height: 64, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }

  // Abre o perfil PÚBLICO da ONG que prestou contas (contraparte).
  void _abrirPerfilOng(int ongId, String ongNome) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PerfilPublicoOngScreen(ongId: ongId, ongNome: ongNome),
      ),
    );
  }

  // Uma prestação (título + descrição + necessidade/data), sem repetir o nome
  // da ONG (ele fica no cabeçalho do grupo).
  Widget _cardPrestacao(PrestacaoRecebida pr) {
    final cs = Theme.of(context).colorScheme;
    final meta = [
      if (pr.necessidadeTitulo.isNotEmpty) pr.necessidadeTitulo,
      if (dataCurtaDeIso(pr.criadoEm).isNotEmpty) dataCurtaDeIso(pr.criadoEm),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pr.titulo,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          if (pr.descricao.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(pr.descricao,
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant, height: 1.4)),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(meta,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _secaoPrestacoes(PerfilPublicoDoador p) {
    final cs = Theme.of(context).colorScheme;

    // Agrupa por ONG (dedupe): várias prestações da MESMA ONG aparecem uma vez
    // sob o nome dela (clicável → perfil da ONG). Sem ongId (backend antigo)
    // cada prestação vira um bloco avulso, com o nome exibido mas sem link.
    // Preserva a ordem de primeira aparição.
    final ordem = <String>[];
    final grupos = <String, List<PrestacaoRecebida>>{};
    for (final pr in p.prestacoesRecebidas) {
      final chave =
          pr.ongId != null ? 'o${pr.ongId}' : 's${identityHashCode(pr)}';
      if (!grupos.containsKey(chave)) {
        grupos[chave] = [];
        ordem.add(chave);
      }
      grupos[chave]!.add(pr);
    }

    final filhos = <Widget>[];
    for (final chave in ordem) {
      final grupo = grupos[chave]!;
      final primeira = grupo.first;
      final nome = primeira.ongNome.trim().isNotEmpty
          ? primeira.ongNome.trim()
          : 'ONG';
      final clicavel = primeira.ongId != null;
      // Cabeçalho da ONG (uma vez por grupo), clicável quando há ongId.
      filhos.add(
        InkWell(
          onTap: clicavel
              ? () => _abrirPerfilOng(primeira.ongId!, nome)
              : null,
          borderRadius: AppRadius.brSm,
          child: Semantics(
            button: clicavel,
            label: clicavel ? 'Abrir perfil da ONG $nome' : null,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.handshake,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (clicavel)
                    Icon(Icons.chevron_right,
                        size: 16, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      );
      for (final pr in grupo) {
        filhos.add(_cardPrestacao(pr));
      }
    }

    return _secao(
        'Prestações de contas recebidas', Icons.receipt_long_outlined, filhos);
  }

  Widget _semHistorico() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'Este doador ainda não tem avaliações nem prestações de contas.',
        textAlign: TextAlign.center,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }
}
