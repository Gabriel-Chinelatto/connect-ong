import 'dart:async';

import 'package:flutter/material.dart';

import '../config/config_controller.dart';
import '../models/interesse.dart';
import '../services/interesse_service.dart';
import '../services/prestacao_service.dart';
import '../services/session_service.dart';
import '../services/avaliacao_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/feedback/empty_state.dart';

import 'chat_screen.dart';
import 'prestacoes_screen.dart';

/// Controlador mínimo para o shell (ou outra aba, ex.: Meu Impacto) pedir que
/// a tela de Matches mude para uma sub-aba: 0=Ativas, 1=Aguardando,
/// 2=Concluídas. Sempre notifica, mesmo repetindo a mesma sub-aba.
class MatchesAbaController extends ChangeNotifier {
  int _aba = 0;
  int get aba => _aba;

  void irPara(int aba) {
    _aba = aba;
    notifyListeners();
  }
}

/// Matches do doador em 3 ABAS:
/// - ATIVAS (ACEITO): conversas em andamento; se houver mais de uma conversa
///   ativa com a MESMA ONG, elas são agrupadas num card expansível da ONG,
///   cada conversa intitulada pelo assunto (título da necessidade);
/// - AGUARDANDO (PENDENTE, e também os recusados, para histórico);
/// - CONCLUÍDAS (CONCLUIDO): histórico estilo "pedidos anteriores", agrupado
///   por data de conclusão, com acesso à prestação de contas.
class MeusMatchesScreen extends StatefulWidget {
  /// Quando presente, o shell usa este controller para abrir uma sub-aba
  /// específica (ex.: cards clicáveis do Meu Impacto).
  final MatchesAbaController? abaController;

  /// true quando esta é a aba VISÍVEL do shell. Controla o polling em tempo
  /// real: só atualiza sozinho enquanto o usuário está de fato nesta aba
  /// (evita bater na API com a tela escondida no IndexedStack). Padrão true
  /// para telas isoladas (harness/testes).
  final bool ativa;

  const MeusMatchesScreen({
    super.key,
    this.abaController,
    this.ativa = true,
  });

  @override
  State<MeusMatchesScreen> createState() => _MeusMatchesScreenState();
}

class _MeusMatchesScreenState extends State<MeusMatchesScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  late final TabController _tabs;

  List<Interesse> _matches = [];
  bool _carregando = true;
  bool _erro = false;

  /// interesseId → a ONG já publicou prestação de contas? (null = ainda
  /// verificando). Preenchido só para os CONCLUÍDOS.
  final Map<int, bool> _temPrestacao = {};

  // ---- Polling em tempo real ----
  // Enquanto a aba está visível, recarrega os interesses de tempos em tempos.
  // Quando a ONG aceita/conclui um interesse, ele muda de aba sozinho e o
  // doador recebe um aviso — sem precisar sair e entrar da tela.
  Timer? _poll;

  /// Último status conhecido por interesseId, para detectar transições
  /// (PENDENTE→ACEITO, →CONCLUIDO) entre uma leitura e a próxima.
  final Map<int, String> _statusConhecido = {};

  // Intervalo do polling: mais espaçado com navegação simplificada (menos
  // movimento/rede para quem prefere calma), curto no uso normal.
  Duration get _intervaloPoll => ConfigController.instance.navegacaoSimplificada
      ? const Duration(seconds: 12)
      : const Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.abaController?.aba ?? 0,
    );
    widget.abaController?.addListener(_aoPedirSubAba);
    _carregar();
    if (widget.ativa) _iniciarPoll();
  }

  @override
  void didUpdateWidget(MeusMatchesScreen old) {
    super.didUpdateWidget(old);
    // O shell troca o valor de [ativa] ao entrar/sair da aba de Matches.
    if (widget.ativa && !old.ativa) {
      _carregar(silencioso: true); // atualiza na hora ao voltar à aba
      _iniciarPoll();
    } else if (!widget.ativa && old.ativa) {
      _pararPoll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pararPoll();
    widget.abaController?.removeListener(_aoPedirSubAba);
    _tabs.dispose();
    super.dispose();
  }

  // Pausa o polling quando o app vai para segundo plano; retoma (e atualiza na
  // hora) ao voltar, se a aba estiver visível.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      if (widget.ativa) {
        _carregar(silencioso: true);
        _iniciarPoll();
      }
    } else if (estado == AppLifecycleState.paused ||
        estado == AppLifecycleState.hidden) {
      _pararPoll();
    }
  }

  void _iniciarPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(_intervaloPoll, (_) {
      if (!mounted || !widget.ativa) return;
      _carregar(silencioso: true);
    });
  }

  void _pararPoll() {
    _poll?.cancel();
    _poll = null;
  }

  void _aoPedirSubAba() {
    if (!mounted) return;
    _tabs.animateTo(widget.abaController!.aba);
  }

  /// Carrega os interesses. Com [silencioso] = true (polling / retorno à aba)
  /// não mostra o spinner nem apaga a lista atual em caso de falha de rede — a
  /// atualização é "invisível" até algo realmente mudar.
  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = false;
      });
    }
    try {
      final usuario = await _sessionService.obterUsuario();
      if (usuario == null) {
        if (!mounted) return;
        setState(() => _carregando = false);
        return;
      }
      final lista = await _interesseService.meusMatches(usuario.id);
      if (!mounted) return;
      _detectarTransicoes(lista, silencioso);
      setState(() {
        _matches = lista;
        _carregando = false;
        _erro = false;
      });
      _verificarPrestacoes(lista);
    } catch (e) {
      // Distingue "sem matches" de "a API caiu". No polling silencioso, uma
      // falha de rede momentânea não deve estragar a tela já carregada.
      if (!mounted) return;
      if (silencioso) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  // Compara os status novos com os últimos conhecidos e avisa o doador quando
  // um interesse foi ACEITO (vira match ativo) ou CONCLUÍDO. Na primeira carga
  // o mapa está vazio, então não dispara avisos falsos.
  void _detectarTransicoes(List<Interesse> lista, bool silencioso) {
    var virouAceito = false;
    var virouConcluido = false;
    for (final i in lista) {
      final anterior = _statusConhecido[i.id];
      if (anterior != null && anterior != i.status) {
        if (i.status == 'ACEITO') virouAceito = true;
        if (i.status == 'CONCLUIDO') virouConcluido = true;
      }
      _statusConhecido[i.id] = i.status;
    }
    // Só avisa em atualização automática (não na carga inicial) e com a tela
    // visível.
    if (!silencioso || !mounted || !widget.ativa) return;
    if (virouAceito) {
      AppSnackbar.sucesso(context, 'Seu interesse foi aceito! 💚 Já dá pra conversar.');
    } else if (virouConcluido) {
      AppSnackbar.sucesso(context, 'Uma doação sua foi concluída! 🎉');
    }
  }

  // Para cada match CONCLUÍDO, verifica (em paralelo, com fallback) se a ONG
  // já publicou prestação de contas — decide entre o botão "Ver prestação de
  // contas" e o aviso "Prestação ainda não publicada".
  Future<void> _verificarPrestacoes(List<Interesse> lista) async {
    final concluidos = lista.where((i) => i.status == 'CONCLUIDO');
    await Future.wait(
      concluidos.map((i) async {
        try {
          final prestacoes = await PrestacaoService().listar(i.id);
          if (!mounted) return;
          setState(() => _temPrestacao[i.id] = prestacoes.isNotEmpty);
        } catch (_) {
          // Na dúvida (falha de rede), deixa null: sem chip de status, mas o
          // botão "Ver prestação de contas" continua visível (a tela de
          // prestações lida com o vazio).
        }
      }),
    );
  }

  // ---- Listas derivadas por aba ----
  List<Interesse> get _ativas =>
      _matches.where((i) => i.status == 'ACEITO').toList();

  List<Interesse> get _aguardando =>
      _matches
          .where((i) => i.status == 'PENDENTE' || i.status == 'RECUSADO')
          .toList();

  List<Interesse> get _concluidas {
    final lista =
        _matches.where((i) => i.status == 'CONCLUIDO').toList()
          // Mais recentes primeiro (datas ISO ordenam lexicograficamente).
          ..sort(
            (a, b) => (b.dataConclusao ?? '').compareTo(a.dataConclusao ?? ''),
          );
    return lista;
  }

  // Cor e rotulo por status do interesse (cores semanticas do tema).
  (Color, String, IconData) _estilo(String status) {
    switch (status) {
      case 'ACEITO':
        return (AppColors.success, 'Aceito', Icons.check_circle);
      case 'RECUSADO':
        return (AppColors.error, 'Recusado', Icons.cancel);
      case 'CONCLUIDO':
        return (AppColors.primary, 'Concluída', Icons.verified);
      default:
        return (AppColors.warning, 'Aguardando', Icons.hourglass_top);
    }
  }

  Widget _acao(IconData icone, String texto, VoidCallback onTap) {
    // TextButton.icon garante area de toque >= 48px (acessibilidade).
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icone, size: 16, color: AppColors.primary),
      label: Text(
        texto,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        minimumSize: const Size(0, 40),
      ),
    );
  }

  void _abrirChat(Interesse i) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              interesseId: i.id,
              meuRemetente: 'DOADOR',
              titulo: i.necessidadeTitulo ?? i.ongNome ?? 'Conversa',
              // Cabeçalho tocável do chat (perfil da ONG) + estado bloqueado.
              ongId: i.ongId,
              ongNome: i.ongNome,
              bloqueadoPelaOng: i.bloqueadoPelaOng,
            ),
      ),
    );
  }

  void _abrirPrestacoes(Interesse i) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PrestacoesScreen(
              interesseId: i.id,
              ongNome: i.ongNome ?? 'ONG',
            ),
      ),
    );
  }

  Future<void> _abrirAvaliar(Interesse i) async {
    if (i.ongId == null) return;
    final u = await _sessionService.obterUsuario();
    if (u == null || !mounted) return;

    int nota = 5;
    final comentarioC = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setStateDialog) => AlertDialog(
                  title: Text('Avaliar ${i.ongNome ?? "ONG"}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (idx) {
                          return IconButton(
                            tooltip:
                                '${idx + 1} ${idx == 0 ? "estrela" : "estrelas"}',
                            icon: Icon(
                              idx < nota
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: AppColors.ouro,
                              size: 32,
                            ),
                            onPressed:
                                () => setStateDialog(() => nota = idx + 1),
                          );
                        }),
                      ),
                      TextField(
                        controller: comentarioC,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Comentário (opcional)',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        try {
                          await AvaliacaoService().avaliar(
                            ongId: i.ongId!,
                            doadorId: u.id,
                            nota: nota,
                            comentario: comentarioC.text.trim(),
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          AppSnackbar.sucesso(
                            context,
                            'Avaliação enviada! Obrigado 💚',
                          );
                        } catch (e) {
                          if (!mounted) return;
                          AppSnackbar.erro(
                            context,
                            e.toString().replaceFirst('Exception: ', ''),
                          );
                        }
                      },
                      child: const Text('Enviar'),
                    ),
                  ],
                ),
          ),
    );

    // Descarta o controller apos o dialogo fechar (evita vazamento).
    comentarioC.dispose();
  }

  // =================== BUILD ===================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Aba do shell: nunca mostra seta de voltar.
        automaticallyImplyLeading: false,
        title: const Text('Meus Matches'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Ativas'),
            Tab(text: 'Aguardando'),
            Tab(text: 'Concluídas'),
          ],
        ),
      ),
      body:
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabs,
                children: [
                  _abaCom(_listaAtivas()),
                  _abaCom(_listaAguardando()),
                  _abaCom(_listaConcluidas()),
                ],
              ),
    );
  }

  // Cada aba tem o próprio pull-to-refresh.
  Widget _abaCom(Widget conteudo) {
    return RefreshIndicator(
      onRefresh: _carregar,
      color: AppColors.primary,
      child: conteudo,
    );
  }

  Widget _erroWidget() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        EmptyState(
          icone: Icons.cloud_off_outlined,
          mensagem: 'Não foi possível carregar',
          detalhe: 'Verifique sua conexão e tente novamente.',
          acaoRotulo: 'Tentar de novo',
          onAcao: _carregar,
        ),
      ],
    );
  }

  Widget _vazio(IconData icone, String mensagem, String detalhe) {
    // Dentro de um ListView para o pull-to-refresh continuar funcionando.
    return ListView(
      children: [
        const SizedBox(height: 100),
        EmptyState(icone: icone, mensagem: mensagem, detalhe: detalhe),
      ],
    );
  }

  // =================== ABA 1: ATIVAS ===================
  Widget _listaAtivas() {
    if (_erro) return _erroWidget();
    final ativas = _ativas;
    if (ativas.isEmpty) {
      return _vazio(
        Icons.handshake_outlined,
        'Nenhuma conversa ativa',
        'Vá ao Explorar e encontre uma causa para apoiar!',
      );
    }

    // Agrupa por ONG preservando a ordem de chegada.
    final grupos = <String, List<Interesse>>{};
    for (final i in ativas) {
      final chave = i.ongId?.toString() ?? i.ongNome ?? '?';
      grupos.putIfAbsent(chave, () => []).add(i);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final grupo in grupos.values)
          if (grupo.length == 1)
            _card(grupo.first) // 1 conversa só: card direto, sem agrupamento
          else
            _cardGrupoOng(grupo),
      ],
    );
  }

  /// Várias conversas ativas com a MESMA ONG: um card da ONG que expande
  /// listando as conversas, cada uma intitulada pelo assunto (necessidade).
  Widget _cardGrupoOng(List<Interesse> grupo) {
    final cs = Theme.of(context).colorScheme;
    final ongNome = grupo.first.ongNome ?? 'ONG';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove as linhas divisórias padrão do ExpansionTile.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            ongNome,
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          subtitle: Text(
            '${grupo.length} conversas ativas',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
          children: [for (final i in grupo) _conversaDoGrupo(i)],
        ),
      ),
    );
  }

  // Uma conversa dentro do grupo da ONG: assunto = título da necessidade.
  Widget _conversaDoGrupo(Interesse i) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _abrirChat(i),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    i.necessidadeTitulo ?? 'Conversa',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: 6,
              children: [
                _acao(
                  Icons.chat_bubble_outline,
                  'Conversar',
                  () => _abrirChat(i),
                ),
                _acao(
                  Icons.receipt_long,
                  'Prestação',
                  () => _abrirPrestacoes(i),
                ),
                _acao(Icons.star_outline, 'Avaliar', () => _abrirAvaliar(i)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =================== ABA 2: AGUARDANDO ===================
  Widget _listaAguardando() {
    if (_erro) return _erroWidget();
    final aguardando = _aguardando;
    if (aguardando.isEmpty) {
      return _vazio(
        Icons.hourglass_empty,
        'Nada aguardando resposta',
        'Demonstre interesse em uma necessidade no Explorar.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: aguardando.length,
      itemBuilder: (context, i) => _card(aguardando[i]),
    );
  }

  // =================== ABA 3: CONCLUÍDAS ===================
  Widget _listaConcluidas() {
    if (_erro) return _erroWidget();
    final concluidas = _concluidas;
    if (concluidas.isEmpty) {
      return _vazio(
        Icons.verified_outlined,
        'Nenhuma doação concluída ainda',
        'Quando uma ONG concluir uma doação sua, ela aparece aqui como histórico.',
      );
    }

    // Histórico estilo iFood: agrupado por data de conclusão (desc).
    final porData = <String, List<Interesse>>{};
    for (final i in concluidas) {
      porData.putIfAbsent(_dataCurta(i.dataConclusao), () => []).add(i);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final entrada in porData.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.sm,
              top: AppSpacing.xs,
            ),
            child: Text(
              entrada.key,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final i in entrada.value) _cardConcluida(i),
        ],
      ],
    );
  }

  Widget _cardConcluida(Interesse i) {
    final cs = Theme.of(context).colorScheme;
    final tem = _temPrestacao[i.id];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.verified, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.necessidadeTitulo ?? 'Doação',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      i.ongNome ?? 'ONG',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Concluída em ${_dataCurta(i.dataConclusao)}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _badgeStatus(AppColors.primary, 'Concluída'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Chip de status da prestação de contas (a checagem por match é a
          // do _verificarPrestacoes): verde suave quando publicada, âmbar
          // enquanto a ONG não publica. tem == null → ainda verificando.
          if (tem != null) ...[
            _chipPrestacao(tem),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (tem != false)
            _acao(
              Icons.receipt_long,
              'Ver prestação de contas',
              () => _abrirPrestacoes(i),
            ),
        ],
      ),
    );
  }

  /// Chip do status da prestação de contas de um match concluído:
  /// verde suave = publicada; âmbar = aguardando a ONG publicar.
  Widget _chipPrestacao(bool publicada) {
    final cor = publicada ? AppColors.success : AppColors.warning;
    final texto =
        publicada
            ? 'Prestação de contas publicada'
            : 'Aguardando prestação de contas';
    return Semantics(
      label: texto,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: AppRadius.brSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              publicada ? Icons.check_circle : Icons.hourglass_top,
              size: 14,
              color: cor,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // "2026-07-03T10:20:00" → "03/07/2026"; sem data → "data não informada".
  String _dataCurta(String? iso) {
    if (iso == null || iso.isEmpty) return 'data não informada';
    final soData = iso.split('T').first;
    final partes = soData.split('-');
    if (partes.length != 3) return soData;
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  // =================== Card padrão (Ativas com 1 conversa / Aguardando) ===================
  Widget _card(Interesse i) {
    final cs = Theme.of(context).colorScheme;
    final (cor, rotulo, icone) = _estilo(i.status);
    final aceito = i.status == 'ACEITO';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brLg,
          onTap: aceito ? () => _abrirChat(i) : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: cor.withValues(alpha: 0.12),
                  child: Icon(icone, color: cor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.necessidadeTitulo ?? 'Necessidade',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i.ongNome ?? 'ONG',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (aceito) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: 6,
                          children: [
                            _acao(
                              Icons.chat_bubble_outline,
                              'Conversar',
                              () => _abrirChat(i),
                            ),
                            _acao(
                              Icons.receipt_long,
                              'Prestação',
                              () => _abrirPrestacoes(i),
                            ),
                            _acao(
                              Icons.star_outline,
                              'Avaliar',
                              () => _abrirAvaliar(i),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _badgeStatus(cor, rotulo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badgeStatus(Color cor, String rotulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: AppRadius.brSm,
      ),
      child: Text(
        rotulo,
        style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
