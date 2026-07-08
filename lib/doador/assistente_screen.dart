import 'package:flutter/material.dart';

import '../models/necessidade.dart';
import '../services/assistente_service.dart';
import '../services/perfil_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'necessidade_detalhe_screen.dart';
import 'perfil_publico_ong_screen.dart';

/// Papel de uma bolha na conversa local.
enum _Papel { usuario, assistente, erro }

/// Uma bolha exibida na tela (mensagem do usuario, do assistente, ou um erro
/// de rede com botao de "tentar de novo").
class _Bolha {
  final _Papel papel;
  final String texto;
  final List<SugestaoAssistente> sugestoes;

  /// Preenchido apenas nas bolhas de erro: a pergunta que falhou, para o
  /// botao "tentar de novo" reenviar exatamente ela.
  final String? perguntaOriginal;

  /// Modo em que o assistente respondeu ('regras' mostra o selo "Modo basico").
  final bool modoRegras;

  const _Bolha({
    required this.papel,
    required this.texto,
    this.sugestoes = const [],
    this.perguntaOriginal,
    this.modoRegras = false,
  });
}

/// Assistente de doacao por chat (estilo o botao de IA do iFood).
///
/// Ajuda o doador a decidir para quem doar ("tenho roupas e nao sei pra
/// quem"), a achar ONGs perto dele e a entender como a doacao funciona.
/// Conversa com `POST /assistente` (via [AssistenteService]) mandando a cidade
/// do doador (do perfil) e as ultimas ~6 trocas da conversa. Quando a resposta
/// traz sugestoes, elas viram cards clicaveis que abrem o perfil da ONG ou o
/// detalhe da necessidade. Degrada com bolha de erro + "tentar de novo".
class AssistenteScreen extends StatefulWidget {
  const AssistenteScreen({super.key});

  @override
  State<AssistenteScreen> createState() => _AssistenteScreenState();
}

class _AssistenteScreenState extends State<AssistenteScreen> {
  final AssistenteService _service = AssistenteService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_Bolha> _bolhas = [];
  bool _enviando = false; // guard anti-duplo-toque + "digitando..."
  String? _cidade; // cidade do doador (do perfil), enviada no request

  // Chips de sugestao de pergunta (mostrados so no inicio, antes da 1ª troca).
  static const List<String> _chipsIniciais = [
    'Tenho roupas para doar',
    'ONGs perto de mim',
    'Como funciona a doacao?',
  ];

  @override
  void initState() {
    super.initState();
    _bolhas.add(const _Bolha(
      papel: _Papel.assistente,
      texto:
          'Ola! Sou o assistente de doacao do Connect ONG. 💚\n\nPosso te '
          'ajudar a decidir para quem doar, encontrar ONGs perto de voce e '
          'tirar duvidas sobre como doar. Como posso ajudar?',
    ));
    _carregarCidade();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Cidade do doador vem do perfil (GET /usuarios/{id}/perfil, campo cidade).
  /// Best-effort: qualquer falha degrada para null (o request vai sem cidade).
  Future<void> _carregarCidade() async {
    try {
      final usuario = await SessionService().obterUsuario();
      if (usuario == null) return;
      final perfil = await PerfilService().obter(usuario.id);
      final cidade = (perfil['cidade'] ?? '').toString().trim();
      if (!mounted) return;
      if (cidade.isNotEmpty) setState(() => _cidade = cidade);
    } catch (_) {
      // Sem cidade: segue a vida, o assistente ainda responde.
    }
  }

  /// Monta o historico recente (ultimas ~6 trocas de user/assistente, sem as
  /// bolhas de erro) no formato do contrato: {papel, texto}.
  List<Map<String, String>> _historico() {
    final trocas = _bolhas
        .where((b) => b.papel != _Papel.erro)
        .map((b) => {
              'papel': b.papel == _Papel.usuario ? 'user' : 'assistente',
              'texto': b.texto,
            })
        .toList();
    if (trocas.length <= 6) return trocas;
    return trocas.sublist(trocas.length - 6);
  }

  Future<void> _enviar(String texto) async {
    final mensagem = texto.trim();
    if (mensagem.isEmpty || _enviando) return;

    // Historico ANTES de adicionar a mensagem atual (a mensagem vai no campo
    // "mensagem" do request, nao no historico).
    final historico = _historico();

    setState(() {
      _bolhas.add(_Bolha(papel: _Papel.usuario, texto: mensagem));
      _enviando = true;
      _controller.clear();
    });
    _irParaOFim();

    try {
      final resposta = await _service.perguntar(
        mensagem: mensagem,
        historico: historico,
        cidade: _cidade,
      );
      if (!mounted) return;
      setState(() {
        _bolhas.add(_Bolha(
          papel: _Papel.assistente,
          texto: resposta.resposta.isNotEmpty
              ? resposta.resposta
              : 'Nao consegui uma resposta agora. Pode reformular?',
          sugestoes: resposta.sugestoes,
          modoRegras: resposta.modoRegras,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bolhas.add(_Bolha(
          papel: _Papel.erro,
          texto: e.toString().replaceFirst('Exception: ', ''),
          perguntaOriginal: mensagem,
        ));
      });
    } finally {
      if (mounted) setState(() => _enviando = false);
      _irParaOFim();
    }
  }

  /// Reenvia a pergunta que falhou (botao "tentar de novo" da bolha de erro):
  /// remove a bolha de erro e a bolha do usuario que a originou, e reenvia.
  void _tentarDeNovo(String pergunta) {
    if (_enviando) return;
    setState(() {
      // Remove a ultima bolha de erro.
      final idxErro = _bolhas.lastIndexWhere((b) => b.papel == _Papel.erro);
      if (idxErro != -1) _bolhas.removeAt(idxErro);
      // Remove a bolha do usuario que gerou o erro (a ultima 'usuario').
      final idxUser =
          _bolhas.lastIndexWhere((b) => b.papel == _Papel.usuario);
      if (idxUser != -1) _bolhas.removeAt(idxUser);
    });
    _enviar(pergunta);
  }

  void _irParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---- Navegacao a partir dos cards de sugestao ----
  void _abrirSugestao(SugestaoAssistente s) {
    if (s.id == null) {
      // Sem id nao da para abrir a tela especifica — degrada silenciosamente.
      return;
    }
    if (s.ehOng) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PerfilPublicoOngScreen(
            ongId: s.id!,
            ongNome: s.titulo,
          ),
        ),
      );
    } else if (s.ehNecessidade) {
      // Monta uma Necessidade minima a partir do que a sugestao trouxe; os
      // campos que faltam degradam graciosamente na tela de detalhe.
      final necessidade = Necessidade(
        id: s.id!,
        titulo: s.titulo,
        descricao: s.subtitulo,
        categoria: '',
        urgente: false,
        status: 'ABERTA',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NecessidadeDetalheScreen(necessidade: necessidade),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Total de itens: bolhas + (bolha "digitando..." quando esperando).
    final mostrarDigitando = _enviando;
    final itemCount = _bolhas.length + (mostrarDigitando ? 1 : 0);
    // Chips so aparecem no comeco (antes de qualquer troca real).
    final mostrarChips =
        _bolhas.where((b) => b.papel == _Papel.usuario).isEmpty && !_enviando;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.auto_awesome,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assistente de doacao',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Tire duvidas e descubra ONGs para ajudar',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: itemCount,
              itemBuilder: (context, i) {
                if (mostrarDigitando && i == _bolhas.length) {
                  return _bolhaDigitando(cs);
                }
                return _construirBolha(_bolhas[i], cs);
              },
            ),
          ),
          if (mostrarChips) _chips(cs),
          _campoEnvio(cs),
        ],
      ),
    );
  }

  Widget _construirBolha(_Bolha b, ColorScheme cs) {
    if (b.papel == _Papel.erro) return _bolhaErro(b, cs);

    final minha = b.papel == _Papel.usuario;
    return Column(
      crossAxisAlignment:
          minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: AppSpacing.md,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: minha ? AppColors.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(minha ? 16 : 4),
                bottomRight: Radius.circular(minha ? 4 : 16),
              ),
            ),
            child: Text(
              b.texto,
              style: TextStyle(
                color: minha ? Colors.white : cs.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ),
        // Cards de sugestao (ONG/NECESSIDADE) abaixo da bolha do assistente.
        if (b.sugestoes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in b.sugestoes) _cardSugestao(s, cs),
              ],
            ),
          ),
        // Selo discreto de "Modo basico" (quando o backend usou regras).
        if (b.modoRegras)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md, top: 2),
            child: Text(
              'Modo basico',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _cardSugestao(SugestaoAssistente s, ColorScheme cs) {
    final ehOng = s.ehOng;
    return Container(
      width: 320,
      margin: const EdgeInsets.only(top: 6),
      child: Material(
        color: cs.surface,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: () => _abrirSugestao(s),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Icon(
                    ehOng ? Icons.corporate_fare : Icons.volunteer_activism,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      if (s.subtitulo.isNotEmpty)
                        Text(
                          s.subtitulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bolhaErro(_Bolha b, ColorScheme cs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: AppSpacing.md,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.10),
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 18, color: AppColors.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    b.texto,
                    style: TextStyle(fontSize: 13, color: cs.onSurface),
                  ),
                ),
              ],
            ),
            if (b.perguntaOriginal != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      _enviando ? null : () => _tentarDeNovo(b.perguntaOriginal!),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Tentar de novo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bolhaDigitando(ColorScheme cs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: AppSpacing.md,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'digitando...',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final chip in _chipsIniciais)
              ActionChip(
                label: Text(chip),
                onPressed: _enviando ? null : () => _enviar(chip),
                backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.30),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _campoEnvio(ColorScheme cs) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Pergunte alguma coisa...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brXl,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brXl,
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (v) => _enviar(v),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: IconButton(
                tooltip: 'Enviar',
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _enviando ? null : () => _enviar(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
