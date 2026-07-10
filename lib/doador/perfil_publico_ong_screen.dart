import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/necessidade.dart';
import '../models/perfil_publico_ong.dart';
import '../services/denuncia_service.dart';
import '../services/perfil_publico_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../widgets/common/dialog_pontuacao.dart';
import '../utils/app_links.dart';
import '../widgets/common/chip_foguinho.dart';
import '../widgets/common/visualizador_imagem.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/empty_state.dart';
import 'necessidade_detalhe_screen.dart';
import 'perfil_publico_doador_screen.dart';

/// Pagina publica de uma ONG: capa (quando cadastrada), avatar, selo de
/// verificacao, nota, streak de 1º lugar, sobre, contato (com endereço +
/// "Abrir no Maps"), fotos do local, campanhas, necessidades, avaliacoes e
/// prestacoes de contas.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
/// Perfil rico (feira 2026-07): capa/endereço/fotosLocal/streak — todos os
/// campos novos são opcionais e degradam graciosamente quando null.
class PerfilPublicoOngScreen extends StatefulWidget {
  final int ongId;
  final String ongNome;

  const PerfilPublicoOngScreen({
    super.key,
    required this.ongId,
    required this.ongNome,
  });

  @override
  State<PerfilPublicoOngScreen> createState() => _PerfilPublicoOngScreenState();
}

class _PerfilPublicoOngScreenState extends State<PerfilPublicoOngScreen> {
  final PerfilPublicoService _service = PerfilPublicoService();
  PerfilPublicoOng? _perfil;
  bool _carregando = true;
  bool _erro = false;

  // Imagens decodificadas UMA vez ao carregar (evita decode a cada frame).
  Uint8List? _capaBytes;
  List<Uint8List> _fotosLocalBytes = [];

  // Guard anti-duplo-toque dos botões de mapa (Abrir no Maps / Como chegar).
  bool _abrindoLink = false;

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
      final p = await _service.buscar(widget.ongId);

      // Decodifica capa e fotos do local; base64 inválido é só ignorado.
      Uint8List? capa;
      if ((p.capaBase64 ?? '').isNotEmpty) {
        try {
          capa = base64Decode(p.capaBase64!);
        } catch (_) {}
      }
      final fotos = <Uint8List>[];
      for (final f in p.fotosLocal) {
        try {
          fotos.add(base64Decode(f));
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _perfil = p;
        _capaBytes = capa;
        _fotosLocalBytes = fotos;
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

  // Compartilhar = LINK público do perfil (o app web abre /#/ong/<id>).
  void _compartilhar() {
    final p = _perfil;
    if (p == null) return;
    Clipboard.setData(ClipboardData(text: linkPerfilOng(p.id)));
    AppSnackbar.sucesso(context, 'Link copiado!');
  }

  // Endereço completo da ONG para o Maps (endereço + cidade, o que existir).
  String _enderecoParaMaps(PerfilPublicoOng p) {
    return [
      if ((p.endereco ?? '').trim().isNotEmpty) p.endereco!.trim(),
      if (p.cidade.trim().isNotEmpty) p.cidade.trim(),
    ].join(', ');
  }

  // Abre o endereço da ONG no Google Maps (busca por endereço + cidade).
  // O helper abrirLink cuida do fallback (copia o link) em qualquer falha.
  Future<void> _abrirNoMaps(PerfilPublicoOng p) async {
    if (_abrindoLink) return; // anti-duplo-toque
    final consulta = _enderecoParaMaps(p);
    if (consulta.isEmpty) return;
    _abrindoLink = true;
    try {
      final uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': consulta,
      });
      await abrirLink(context, uri);
    } finally {
      _abrindoLink = false;
    }
  }

  // Abre a ROTA até a ONG no Google Maps. Sem `origin`: o Maps usa a
  // localização atual do usuário e traça o caminho (GPS grátis, sem API paga).
  Future<void> _abrirComoChegar(PerfilPublicoOng p) async {
    if (_abrindoLink) return; // anti-duplo-toque
    final destino = _enderecoParaMaps(p);
    if (destino.isEmpty) return;
    _abrindoLink = true;
    try {
      final uri = Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': destino,
      });
      await abrirLink(context, uri);
    } finally {
      _abrindoLink = false;
    }
  }

  // Abre o dialog de denuncia da ONG.
  Future<void> _abrirDenuncia() async {
    const motivos = <String, String>{
      'CONTEUDO_INADEQUADO': 'Conteudo inadequado',
      'FRAUDE': 'Suspeita de fraude',
      'SPAM': 'Spam',
      'ABUSO': 'Abuso',
      'OUTRO': 'Outro',
    };
    String motivoSelecionado = 'CONTEUDO_INADEQUADO';
    final descricaoController = TextEditingController();
    bool enviando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> enviar() async {
              setStateDialog(() => enviando = true);
              try {
                final u = await SessionService().obterUsuario();
                await DenunciaService().criar(
                  denuncianteId: u?.id,
                  tipoAlvo: 'ONG',
                  alvoId: widget.ongId,
                  motivo: motivoSelecionado,
                  descricao: descricaoController.text.trim(),
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                AppSnackbar.sucesso(context, 'Denuncia enviada. Obrigado.');
              } catch (_) {
                if (!dialogContext.mounted) return;
                setStateDialog(() => enviando = false);
                AppSnackbar.erro(
                  dialogContext,
                  'Nao foi possivel enviar a denuncia.',
                );
              }
            }

            return AlertDialog(
              title: Text(
                'Denunciar ONG',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: motivoSelecionado,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Motivo'),
                    items: [
                      for (final e in motivos.entries)
                        DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, style: TextStyle()),
                        ),
                    ],
                    onChanged:
                        enviando
                            ? null
                            : (v) {
                              if (v != null) {
                                setStateDialog(() => motivoSelecionado = v);
                              }
                            },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descricaoController,
                    maxLines: 3,
                    enabled: !enviando,
                    decoration: const InputDecoration(
                      labelText: 'Detalhes (opcional)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      enviando ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: enviando ? null : enviar,
                  child:
                      enviando
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );

    // Descarta o controller apos o dialogo fechar (evita vazamento).
    descricaoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // ONG bloqueou o doador: o backend devolve só {id, nome, bloqueado:true}
    // e a tela vira o estado mínimo, sem ações nem dados do perfil.
    final bloqueado = _perfil?.bloqueado ?? false;
    return Scaffold(
      appBar: AppBar(
        // Usa o nome carregado da API quando o chamador só tinha um
        // placeholder (ex.: link compartilhado /#/ong/<id> na web).
        title: Text(_perfil?.nome ?? widget.ongNome),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        // Perfil bloqueado: sem Compartilhar/Denunciar (nenhuma ação).
        actions:
            bloqueado
                ? null
                : [
                  IconButton(
                    tooltip: 'Como funciona a transparência',
                    onPressed: () => mostrarComoPontuar(context),
                    icon: const Icon(Icons.info_outline),
                  ),
                  if (_perfil != null)
                    IconButton(
                      tooltip: 'Compartilhar',
                      onPressed: _compartilhar,
                      icon: const Icon(Icons.share_outlined),
                    ),
                  IconButton(
                    tooltip: 'Denunciar',
                    onPressed: _abrirDenuncia,
                    icon: const Icon(Icons.flag_outlined),
                  ),
                ],
      ),
      body:
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : _erro || _perfil == null
              ? _vazio()
              : bloqueado
              ? _telaBloqueado(_perfil!)
              : RefreshIndicator(
                onRefresh: _carregar,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _cabecalho(_perfil!),
                    if (_perfil!.diasNoTopo == null &&
                        (_perfil!.ultimoReinadoDias ?? 0) > 0)
                      _linhaUltimoReinado(_perfil!.ultimoReinadoDias!),
                    _statsRow(_perfil!),
                    _secaoSobre(_perfil!),
                    _secaoContato(_perfil!),
                    if (_fotosLocalBytes.isNotEmpty) _secaoFotosLocal(),
                    if (_perfil!.campanhas.isNotEmpty)
                      _secaoCampanhas(_perfil!),
                    if (_perfil!.necessidades.isNotEmpty)
                      _secaoNecessidades(_perfil!),
                    if (_perfil!.prestacoes.isNotEmpty)
                      _secaoPrestacoes(_perfil!),
                    if (_perfil!.avaliacoes.isNotEmpty)
                      _secaoAvaliacoes(_perfil!),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
    );
  }

  Widget _vazio() {
    return EmptyState(
      icone: Icons.error_outline,
      mensagem: 'Não foi possível carregar o perfil',
      acaoRotulo: 'Tentar de novo',
      onAcao: _carregar,
    );
  }

  // Estado mínimo quando a ONG bloqueou o doador: ícone + nome + aviso,
  // centrado e digno — sem capa, endereço, fotos ou qualquer outro dado.
  Widget _telaBloqueado(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              p.nome.isNotEmpty ? p.nome : widget.ongNome,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Você não pode ver este perfil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Cabecalho: capa (se houver) ou gradiente verde ----------
  //
  // Com capa cadastrada, ela vira o fundo (cover) com um gradiente escuro
  // por cima para o nome/selo continuarem legíveis. Sem capa, mantém o
  // header verde original.
  Widget _cabecalho(PerfilPublicoOng p) {
    final inicial = p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?';
    final temCapa = _capaBytes != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        image:
            temCapa
                ? DecorationImage(
                  image: MemoryImage(_capaBytes!),
                  fit: BoxFit.cover,
                  // Escurece a CAPA (não o conteúdo) para o texto branco do
                  // header continuar legível sobre qualquer foto.
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.45),
                    BlendMode.darken,
                  ),
                )
                : null,
        gradient:
            temCapa
                ? null
                : const LinearGradient(
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              inicial,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  p.nome,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (p.verificada) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: Colors.white, size: 22),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_city_outlined,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(p.cidade, style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          _estrelas(p.notaMedia, p.totalAvaliacoes),
          const SizedBox(height: 10),
          _pillTransparencia(p.nivelTransparencia, p.transparenciaScore),
          // Streak 🔥: presente apenas quando a ONG é a ATUAL #1 do ranking.
          if (p.diasNoTopo != null) ...[
            const SizedBox(height: 10),
            ChipFoguinho(dias: p.diasNoTopo!),
          ],
        ],
      ),
    );
  }

  // Linha discreta para ONGs que JÁ foram #1 e saíram do topo.
  Widget _linhaUltimoReinado(int dias) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Já ficou $dias ${dias == 1 ? "dia" : "dias"} em 1º lugar no '
              'ranking de transparência',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  // Cor da medalha por nivel de transparencia (tokens centralizados).
  Color _corNivel(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'OURO':
        return AppColors.ouro;
      case 'PRATA':
        return AppColors.prata;
      case 'BRONZE':
      default:
        return AppColors.bronze;
    }
  }

  // Rotulo amigavel (primeira maiuscula) do nivel.
  String _rotuloNivel(String nivel) {
    final n = nivel.toLowerCase();
    if (n.isEmpty) return 'Bronze';
    return n[0].toUpperCase() + n.substring(1);
  }

  Widget _pillTransparencia(String nivel, int score) {
    final cor = _corNivel(nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: cor, size: 18),
          const SizedBox(width: 6),
          Text(
            'Transparencia: ${_rotuloNivel(nivel)} ($score)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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
          Icon(
            i < cheias ? Icons.star : Icons.star_border,
            color: AppColors.ouro,
            size: 20,
          ),
        const SizedBox(width: 8),
        Text(
          total > 0 ? '${nota.toStringAsFixed(1)} ($total)' : 'Sem avaliacoes',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }

  // ---------- Linha de estatisticas ----------
  Widget _statsRow(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;
    Widget item(IconData icon, int valor, String label) => Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 6),
          Text(
            '$valor',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: cs.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
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
          item(Icons.favorite_outline, p.totalNecessidades, 'Necessidades'),
          item(Icons.campaign_outlined, p.totalCampanhas, 'Campanhas'),
          item(Icons.receipt_long_outlined, p.totalPrestacoes, 'Prestacoes'),
        ],
      ),
    );
  }

  // ---------- Cartao de secao generico ----------
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
              Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...filhos,
        ],
      ),
    );
  }

  Widget _secaoSobre(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;
    return _secao('Sobre', Icons.info_outline, [
      Text(
        p.descricao.isNotEmpty
            ? p.descricao
            : 'Esta ONG ainda nao tem descricao.',
        style: TextStyle(fontSize: 14, height: 1.5, color: cs.onSurface),
      ),
    ]);
  }

  Widget _secaoContato(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;
    Widget linha(IconData icon, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
    final temEndereco = (p.endereco ?? '').trim().isNotEmpty;
    // Botões de mapa aparecem com endereço OU cidade (o Maps resolve ambos).
    final temLocal = temEndereco || p.cidade.trim().isNotEmpty;
    return _secao('Contato', Icons.contact_mail_outlined, [
      // E-mail/telefone só quando o backend os envia: com os toggles de
      // privacidade da ONG, os campos vêm omitidos e a linha some.
      if (p.email.trim().isNotEmpty) linha(Icons.email_outlined, p.email),
      if (p.telefone.trim().isNotEmpty) linha(Icons.phone_outlined, p.telefone),
      if (p.cnpj != null && p.cnpj!.isNotEmpty)
        linha(Icons.badge_outlined, 'CNPJ: ${p.cnpj}'),
      if (temEndereco) linha(Icons.place_outlined, p.endereco!.trim()),
      if (temLocal)
        // Wrap: lado a lado quando cabem; quebram bem com fonte grande.
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: () => _abrirNoMaps(p),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Abrir no Maps'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            TextButton.icon(
              onPressed: () => _abrirComoChegar(p),
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Como chegar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
    ]);
  }

  // ---------- Fotos do local (galeria horizontal + tela cheia) ----------
  Widget _secaoFotosLocal() {
    return _secao('Fotos do local', Icons.photo_library_outlined, [
      SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _fotosLocalBytes.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final bytes = _fotosLocalBytes[i];
            return Semantics(
              button: true,
              label: 'Foto ${i + 1} do local, toque para ampliar',
              child: InkWell(
                borderRadius: AppRadius.brMd,
                onTap:
                    () => VisualizadorImagem.abrir(
                      context,
                      bytes,
                      titulo: 'Foto do local',
                    ),
                child: ClipRRect(
                  borderRadius: AppRadius.brMd,
                  child: Image.memory(
                    bytes,
                    width: 140,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _secaoCampanhas(PerfilPublicoOng p) {
    return _secao('Campanhas', Icons.campaign_outlined, [
      for (final c in p.campanhas) _cardCampanha(c),
    ]);
  }

  Widget _cardCampanha(CampanhaResumo c) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (c.encerrada)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Encerrada',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: c.progresso / 100,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${c.valorArrecadado.toStringAsFixed(0)} de '
            'R\$ ${c.metaValor.toStringAsFixed(0)} (${c.progresso}%)',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // Abre o DETALHE de uma necessidade da ONG (onde o doador pode demonstrar
  // interesse ou ver "já demonstrado"). Constrói um [Necessidade] completo a
  // partir do resumo do perfil + os dados desta ONG (id/nome/cidade/nota).
  void _abrirNecessidade(PerfilPublicoOng p, NecessidadeResumo n) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NecessidadeDetalheScreen(
          necessidade: Necessidade(
            id: n.id,
            titulo: n.titulo,
            descricao: n.descricao,
            categoria: n.categoria,
            urgente: n.urgente,
            status: n.status,
            ongId: p.id,
            ongNome: p.nome,
            ongCidade: p.cidade,
            ongVerificada: p.verificada,
            ongNotaMedia: p.notaMedia,
            ongTotalAvaliacoes: p.totalAvaliacoes,
          ),
        ),
      ),
    );
  }

  Widget _secaoNecessidades(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;
    return _secao('Necessidades', Icons.favorite_outline, [
      for (final n in p.necessidades)
        // Cada necessidade é TOCÁVEL: abre o detalhe (demonstrar interesse).
        InkWell(
          onTap: () => _abrirNecessidade(p, n),
          borderRadius: AppRadius.brSm,
          child: Semantics(
            button: true,
            label: 'Abrir necessidade ${n.titulo}',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    n.urgente ? Icons.priority_high : Icons.circle,
                    size: n.urgente ? 18 : 8,
                    color: n.urgente ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.titulo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        if (n.categoria.isNotEmpty)
                          Text(
                            n.categoria,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (n.urgente)
                    Text(
                      'Urgente',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 18, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
    ]);
  }

  // Abre o perfil PÚBLICO de um doador (contraparte de uma prestação).
  void _abrirPerfilDoador(int usuarioId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilPublicoDoadorScreen(usuarioId: usuarioId),
      ),
    );
  }

  // Card de uma prestação (título + descrição), reutilizado dentro e fora dos
  // grupos por doador.
  Widget _cardPrestacao(PrestacaoResumo pr) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pr.titulo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          if (pr.descricao.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              pr.descricao,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _secaoPrestacoes(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;

    // Agrupa por doador BENEFICIÁRIO (dedupe): prestações do mesmo doador
    // aparecem uma vez sob "para <doador>" (clicável). Prestações sem doadorId
    // (backend antigo / gerais) degradam para blocos avulsos, sem link. A
    // ordem de primeira aparição é preservada.
    final ordem = <String>[];
    final grupos = <String, List<PrestacaoResumo>>{};
    for (final pr in p.prestacoes) {
      final chave = pr.doadorId != null
          ? 'd${pr.doadorId}'
          : 's${identityHashCode(pr)}';
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
      final temDoador = primeira.doadorId != null;
      if (temDoador) {
        final nome = (primeira.doadorNome ?? 'Doador').trim();
        filhos.add(
          InkWell(
            onTap: () => _abrirPerfilDoador(primeira.doadorId!),
            borderRadius: AppRadius.brSm,
            child: Semantics(
              button: true,
              label: 'Abrir perfil do doador $nome',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'para $nome',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 14, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      for (final pr in grupo) {
        filhos.add(_cardPrestacao(pr));
      }
    }

    return _secao('Prestacoes de contas', Icons.receipt_long_outlined, filhos);
  }

  Widget _secaoAvaliacoes(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;
    return _secao('Avaliacoes', Icons.star_outline, [
      // Selo de confianca: comunica que a reputacao tem lastro (o backend so
      // aceita avaliacao de quem concluiu uma doacao com esta ONG).
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(Icons.verified_user_outlined,
                size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Só quem concluiu uma doação com esta ONG pode avaliar.',
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
                  Text(
                    a.doadorNome,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (int i = 0; i < 5; i++)
                    Icon(
                      i < a.nota ? Icons.star : Icons.star_border,
                      size: 14,
                      color: AppColors.ouro,
                    ),
                ],
              ),
              if (a.comentario != null && a.comentario!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  a.comentario!,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
    ]);
  }
}
