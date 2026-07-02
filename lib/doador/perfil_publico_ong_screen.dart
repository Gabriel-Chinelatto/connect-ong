import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/perfil_publico_ong.dart';
import '../services/denuncia_service.dart';
import '../services/perfil_publico_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/empty_state.dart';

/// Pagina publica de uma ONG: avatar, selo de verificacao, nota, sobre,
/// contato, campanhas, necessidades, avaliacoes e prestacoes de contas.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
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
      if (!mounted) return;
      setState(() {
        _perfil = p;
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

  void _compartilhar() {
    final p = _perfil;
    if (p == null) return;
    final texto = StringBuffer()
      ..writeln(p.nome + (p.verificada ? ' (ONG Verificada)' : ''))
      ..writeln('Cidade: ${p.cidade}')
      ..writeln(p.descricao)
      ..writeln(
          'Avaliacao: ${p.notaMedia.toStringAsFixed(1)} (${p.totalAvaliacoes} avaliacoes)')
      ..writeln('Conheca no Connect ONG.');
    Clipboard.setData(ClipboardData(text: texto.toString()));
    AppSnackbar.sucesso(context, 'Perfil copiado para compartilhar!');
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
                    dialogContext, 'Nao foi possivel enviar a denuncia.');
              }
            }

            return AlertDialog(
              title: Text('Denunciar ONG',
                  style: TextStyle(fontWeight: FontWeight.w700)),
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
                    onChanged: enviando
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
                    decoration:
                        const InputDecoration(labelText: 'Detalhes (opcional)'),
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
                  child: enviando
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ongNome),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
        actions: [
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
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro || _perfil == null
              ? _vazio()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _cabecalho(_perfil!),
                      _statsRow(_perfil!),
                      _secaoSobre(_perfil!),
                      _secaoContato(_perfil!),
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

  // ---------- Cabecalho com avatar de inicial + selo + nota ----------
  Widget _cabecalho(PerfilPublicoOng p) {
    final inicial = p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?';
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(inicial,
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(p.nome,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
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
              const Icon(Icons.location_city_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(p.cidade,
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          _estrelas(p.notaMedia, p.totalAvaliacoes),
          const SizedBox(height: 10),
          _pillTransparencia(p.nivelTransparencia, p.transparenciaScore),
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
                fontWeight: FontWeight.w600),
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
              : 'Sem avaliacoes',
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
              Text('$valor',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: cs.onSurface)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
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
              Text(titulo,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: cs.onSurface)),
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
        p.descricao.isNotEmpty ? p.descricao : 'Esta ONG ainda nao tem descricao.',
        style: TextStyle(
            fontSize: 14, height: 1.5, color: cs.onSurface),
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
                  child: Text(texto,
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurface))),
            ],
          ),
        );
    return _secao('Contato', Icons.contact_mail_outlined, [
      linha(Icons.email_outlined, p.email),
      linha(Icons.phone_outlined, p.telefone),
      if (p.cnpj != null && p.cnpj!.isNotEmpty)
        linha(Icons.badge_outlined, 'CNPJ: ${p.cnpj}'),
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
                child: Text(c.titulo,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface)),
              ),
              if (c.encerrada)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Encerrada',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${c.valorArrecadado.toStringAsFixed(0)} de '
            'R\$ ${c.metaValor.toStringAsFixed(0)} (${c.progresso}%)',
            style: TextStyle(
                fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _secaoNecessidades(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;
    return _secao('Necessidades', Icons.favorite_outline, [
      for (final n in p.necessidades)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
                    Text(n.titulo,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                    if (n.categoria.isNotEmpty)
                      Text(n.categoria,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              if (n.urgente)
                Text('Urgente',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ),
    ]);
  }

  Widget _secaoPrestacoes(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;
    return _secao('Prestacoes de contas', Icons.receipt_long_outlined, [
      for (final pr in p.prestacoes)
        Padding(
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
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.4)),
              ],
            ],
          ),
        ),
    ]);
  }

  Widget _secaoAvaliacoes(PerfilPublicoOng p) {
    final cs = Theme.of(context).colorScheme;
    return _secao('Avaliacoes', Icons.star_outline, [
      for (final a in p.avaliacoes)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(a.doadorNome,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  const SizedBox(width: 8),
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
            ],
          ),
        ),
    ]);
  }
}
