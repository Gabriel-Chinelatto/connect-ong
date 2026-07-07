import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';

import '../config/config_controller.dart';
import '../models/preferencia.dart';
import '../models/usuario_logado.dart';
import '../pages/login_page.dart';
import '../services/api_service.dart';
import '../services/perfil_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/page_transition.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../screens/legal/documentos_legais_screen.dart';

/// Central de configuracoes do doador: aparencia, acessibilidade,
/// notificacoes, privacidade, seguranca e area legal.
///
/// Fluxo de edicao (rascunho + Salvar):
/// - Os toggles alteram uma COPIA local ([_p]) e mostram um PREVIEW imediato
///   via [ConfigController.aplicarPreview] (tema/contraste/fonte mudam na
///   hora, sem persistir).
/// - "Salvar configuracoes" (barra fixa que aparece so com mudanca pendente)
///   persiste tudo via [ConfigController.atualizar]; "Descartar" (ou sair da
///   tela sem salvar) reverte o preview com [ConfigController.reverterPreview].
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  /// Snapshot do estado persistido no momento em que a tela abriu (ou do
  /// ultimo salvar): e a referencia para saber se ha mudanca pendente.
  late Preferencia _original;

  /// Copia PENDENTE que os toggles editam (so vira definitiva no Salvar).
  late Preferencia _p;

  int? _usuarioId;
  bool _excluindo = false;
  bool _salvando = false; // guard anti-duplo-toque do Salvar

  /// Ha mudanca pendente? (compara a copia editada com o snapshot original)
  bool get _temMudanca => !mapEquals(_p.toJson(), _original.toJson());

  @override
  void initState() {
    super.initState();
    _original = ConfigController.instance.prefs.copy();
    _p = _original.copy();
    SessionService().obterUsuario().then((u) {
      if (mounted) setState(() => _usuarioId = u?.id);
    });
  }

  /// Aplica a edicao como PREVIEW (visual imediato, sem persistir).
  void _editar(void Function() muda) {
    setState(muda);
    ConfigController.instance.aplicarPreview(_p);
  }

  /// Persiste as mudancas pendentes. Retorna true se concluiu.
  Future<bool> _salvar() async {
    if (_salvando) return false; // anti-duplo-toque
    setState(() => _salvando = true);
    await ConfigController.instance.atualizar(_p.copy());
    if (!mounted) return true;
    setState(() {
      _original = _p.copy();
      _salvando = false;
    });
    AppSnackbar.sucesso(context, 'Configurações salvas 💚');
    return true;
  }

  /// Descarta as mudancas pendentes e reverte o preview.
  void _descartar() {
    ConfigController.instance.reverterPreview();
    setState(() => _p = _original.copy());
  }

  /// Dialog ao tentar sair com mudancas pendentes.
  Future<void> _confirmarSaida() async {
    final escolha = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
            'Você mudou algumas configurações mas ainda não salvou.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'editar'),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'descartar'),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'salvar'),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    switch (escolha) {
      case 'salvar':
        final ok = await _salvar();
        if (ok && mounted) Navigator.pop(context);
      case 'descartar':
        _descartar();
        Navigator.pop(context);
      default:
        break; // continuar editando (ou dialog fechado)
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Sem pendencias, sai normal; com pendencias, intercepta e pergunta.
      canPop: !_temMudanca,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmarSaida();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurações'),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        body: Stack(
          children: [
            ListView(
              // Espaco extra embaixo para a barra de salvar nao cobrir a
              // ultima secao.
              padding: const EdgeInsets.fromLTRB(
                  0, AppSpacing.sm, 0, AppSpacing.xxl * 2.5),
              children: [
                _cartaoSecao(
                  icone: Icons.palette_outlined,
                  titulo: 'Aparência',
                  subtitulo: 'Tema e tamanho do texto',
                  filhos: [
                    _escolha(
                      'Tema',
                      'Claro, escuro ou acompanha o aparelho',
                      const ['CLARO', 'ESCURO', 'AUTOMATICO'],
                      const ['Claro', 'Escuro', 'Automático'],
                      _p.tema,
                      (v) => _editar(() => _p.tema = v),
                    ),
                    _escolha(
                      'Tamanho da fonte',
                      'Ajusta o tamanho do texto em todo o app',
                      const ['PEQUENA', 'MEDIA', 'GRANDE'],
                      const ['Pequena', 'Média', 'Grande'],
                      _p.tamanhoFonte,
                      (v) => _editar(() => _p.tamanhoFonte = v),
                    ),
                  ],
                ),
                _cartaoSecao(
                  icone: Icons.accessibility_new_outlined,
                  titulo: 'Acessibilidade',
                  subtitulo: 'Recursos para facilitar o uso',
                  filhos: [
                    _switch(
                        'Alto contraste',
                        'Fundos puros, bordas marcadas e cores mais fortes',
                        _p.altoContraste,
                        (v) => _editar(() => _p.altoContraste = v)),
                    _switch(
                        'Fonte para dislexia',
                        'Troca para a fonte Lexend, mais fácil de ler',
                        _p.fonteDislexia,
                        (v) => _editar(() => _p.fonteDislexia = v)),
                    _switch(
                        'Navegação simplificada',
                        'Reduz animações e movimentos automáticos',
                        _p.navegacaoSimplificada,
                        (v) => _editar(() => _p.navegacaoSimplificada = v)),
                  ],
                ),
                _cartaoSecao(
                  icone: Icons.notifications_outlined,
                  titulo: 'Notificações',
                  subtitulo: 'O que você quer receber',
                  filhos: [
                    _switch(
                        'Novas mensagens',
                        'Avisa quando uma ONG responder no chat',
                        _p.notifMensagens,
                        (v) => _editar(() => _p.notifMensagens = v)),
                    _switch(
                        'Match de doações',
                        'Avisa quando uma ONG aceitar sua doação',
                        _p.notifMatch,
                        (v) => _editar(() => _p.notifMatch = v)),
                    _switch(
                        'Atualizações de campanhas',
                        'Novidades das campanhas que você acompanha',
                        _p.notifCampanhas,
                        (v) => _editar(() => _p.notifCampanhas = v)),
                    _switch(
                        'Novas necessidades',
                        'Quando as ONGs publicarem novos pedidos',
                        _p.notifNecessidades,
                        (v) => _editar(() => _p.notifNecessidades = v)),
                    _switch(
                        'Notícias da plataforma',
                        'Novidades e avisos do Connect ONG',
                        _p.notifNoticias,
                        (v) => _editar(() => _p.notifNoticias = v)),
                  ],
                ),
                _cartaoSecao(
                  icone: Icons.lock_outline,
                  titulo: 'Privacidade',
                  subtitulo: 'O que os outros veem sobre você',
                  filhos: [
                    _switch(
                        'Exibir telefone',
                        'Mostra seu telefone para ONGs com match',
                        _p.mostrarTelefone,
                        (v) => _editar(() => _p.mostrarTelefone = v)),
                    _switch(
                        'Exibir e-mail',
                        'Mostra seu e-mail no seu perfil público',
                        _p.mostrarEmail,
                        (v) => _editar(() => _p.mostrarEmail = v)),
                    _switch(
                        'Perfil público',
                        'Permite que outros vejam seu perfil de doador',
                        _p.perfilPublico,
                        (v) => _editar(() => _p.perfilPublico = v)),
                    _switch(
                        'Receber contatos de ONGs',
                        'ONGs podem iniciar uma conversa com você',
                        _p.receberContatos,
                        (v) => _editar(() => _p.receberContatos = v)),
                    _switch(
                        'Receber sugestões',
                        'Sugestões de ONGs e necessidades para você',
                        _p.receberSugestoes,
                        (v) => _editar(() => _p.receberSugestoes = v)),
                  ],
                ),
                _cartaoSecao(
                  icone: Icons.shield_outlined,
                  titulo: 'Segurança',
                  subtitulo: 'Proteja o acesso à sua conta',
                  filhos: [
                    ListTile(
                      leading: const Icon(Icons.password),
                      title: const Text('Alterar senha'),
                      subtitle: const Text('Troque sua senha de acesso'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _abrirAlterarSenha,
                    ),
                    ListTile(
                      leading: const Icon(Icons.alternate_email),
                      title: const Text('Alterar e-mail'),
                      subtitle: const Text('Troque o e-mail de acesso'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _abrirAlterarEmail,
                    ),
                    _switch(
                        'Verificação em duas etapas',
                        'A cada login enviaremos um código para confirmar que é você',
                        _p.doisFatores,
                        (v) => _editar(() => _p.doisFatores = v)),
                  ],
                ),
                _cartaoSecao(
                  icone: Icons.storefront_outlined,
                  titulo: 'Apresentação',
                  subtitulo: 'Recursos para demonstrações',
                  filhos: [
                    // Preferencia LOCAL do aparelho: aplica e salva na hora
                    // (nao entra no fluxo de rascunho/Salvar).
                    _switch(
                      'Modo Feira',
                      'Mostra as credenciais de demonstração na tela de login',
                      ConfigController.instance.modoFeira,
                      (v) {
                        ConfigController.instance.definirModoFeira(v);
                        setState(() {});
                      },
                    ),
                  ],
                ),
                _cartaoSecao(
                  icone: Icons.gavel_outlined,
                  titulo: 'Termos e Privacidade',
                  subtitulo: 'Documentos legais da plataforma',
                  filhos: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Política de Privacidade'),
                      subtitle:
                          const Text('Como tratamos seus dados (LGPD)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          _abrirDocumento(DocumentoLegal.privacidade),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Termos de Uso'),
                      subtitle: const Text('Regras de uso da plataforma'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _abrirDocumento(DocumentoLegal.termos),
                    ),
                  ],
                ),
                // Zona de perigo: acao destrutiva, destacada em vermelho.
                _cartaoSecao(
                  icone: Icons.warning_amber_rounded,
                  titulo: 'Zona de perigo',
                  subtitulo: 'Ações permanentes na sua conta',
                  cor: AppColors.error,
                  filhos: [
                    ListTile(
                      leading: const Icon(Icons.delete_forever,
                          color: AppColors.error),
                      title: const Text(
                        'Excluir minha conta',
                        style: TextStyle(color: AppColors.error),
                      ),
                      subtitle:
                          const Text('Desativa sua conta permanentemente'),
                      onTap: _excluindo ? null : _confirmarExcluirConta,
                    ),
                  ],
                ),
              ],
            ),
            // Barra fixa de Salvar/Descartar: so aparece com mudanca pendente.
            Align(
              alignment: Alignment.bottomCenter,
              child: _barraSalvar(),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Barra fixa "Salvar configurações" / "Descartar" ----
  Widget _barraSalvar() {
    final cs = Theme.of(context).colorScheme;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: _temMudanca ? Offset.zero : const Offset(0, 1.2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _temMudanca ? 1 : 0,
        child: IgnorePointer(
          ignoring: !_temMudanca,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _salvando ? null : _descartar,
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.brMd),
                      ),
                      child: const Text('Descartar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.brMd),
                      ),
                      icon: _salvando
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                          _salvando ? 'Salvando...' : 'Salvar configurações'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirDocumento(DocumentoLegal tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentosLegaisScreen(tipo: tipo),
      ),
    );
  }

  // Confirma e executa a exclusao (soft-delete) da propria conta.
  Future<void> _confirmarExcluirConta() async {
    if (_excluindo) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir minha conta?'),
        content: const Text(
          'Tem certeza? Sua conta será desativada e você não poderá mais '
          'acessá-la. Esta ação não pode ser desfeita pelo app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    if (!mounted) return;

    // Anti-duplo-toque: nao dispara duas exclusoes.
    setState(() => _excluindo = true);

    try {
      final usuario = await SessionService().obterUsuario();
      if (!mounted) return;
      if (usuario == null) {
        setState(() => _excluindo = false);
        AppSnackbar.erro(context, 'Sessão expirada. Entre novamente.');
        return;
      }

      await PerfilService().excluirConta(usuario.id);
      if (!mounted) return;

      // Mesmo fluxo do logout: limpa sessao/token + preferencias e volta ao login.
      await SessionService().logout();
      ConfigController.instance.limpar();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, PageTransition.fade(const LoginPage()));
      AppSnackbar.sucesso(context, 'Conta excluída.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _excluindo = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  // ---- Componentes visuais das secoes ----

  /// Card de secao: cabecalho com icone em "pilula" + titulo + subtitulo,
  /// seguido dos itens da secao.
  Widget _cartaoSecao({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required List<Widget> filhos,
    Color? cor,
  }) {
    final Color destaque = cor ?? Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: destaque.withValues(alpha: 0.12),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Icon(icone, size: 22, color: destaque),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cor ?? cs.onSurface,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...filhos,
          ],
        ),
      ),
    );
  }

  Widget _switch(String titulo, String subtitulo, bool valor,
      ValueChanged<bool> onChange) {
    return SwitchListTile(
      title: Text(titulo),
      subtitle: Text(subtitulo),
      value: valor,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      onChanged: onChange,
    );
  }

  Widget _escolha(
    String titulo,
    String subtitulo,
    List<String> valores,
    List<String> rotulos,
    String selecionado,
    ValueChanged<String> onChange,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo),
          Text(
            subtitulo,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: List.generate(valores.length, (i) {
              final sel = valores[i] == selecionado;
              return ChoiceChip(
                label: Text(rotulos[i]),
                selected: sel,
                selectedColor: cs.primary,
                labelStyle: TextStyle(
                  color: sel ? cs.onPrimary : null,
                ),
                onSelected: (_) => onChange(valores[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirAlterarSenha() async {
    final atualController = TextEditingController();
    final novaController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: atualController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: novaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) => (v == null || v.length < 4)
                    ? 'Mínimo 4 caracteres'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (_usuarioId == null) return;
              try {
                await PerfilService().alterarSenha(
                  _usuarioId!,
                  atualController.text,
                  novaController.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                AppSnackbar.sucesso(context, 'Senha alterada com sucesso! 💚');
              } catch (e) {
                if (!dialogContext.mounted) return;
                AppSnackbar.erro(dialogContext,
                    e.toString().replaceFirst('Exception: ', ''));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    // Descarta os controllers apos o dialogo fechar (evita vazamento).
    atualController.dispose();
    novaController.dispose();
  }

  Future<void> _abrirAlterarEmail() async {
    final emailController = TextEditingController();
    final senhaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool salvando = false; // guard anti-duplo-toque dentro do dialog

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          title: const Text('Alterar e-mail'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Novo e-mail'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Informe o novo e-mail';
                    final ok = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$')
                        .hasMatch(t);
                    return ok ? null : 'E-mail inválido';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha atual'),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Informe a senha atual'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  salvando ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (_usuarioId == null) return;
                      setStateDialog(() => salvando = true);
                      try {
                        final resp = await PerfilService().alterarEmail(
                          _usuarioId!,
                          emailController.text.trim(),
                          senhaController.text,
                        );
                        // Atualiza a sessao com o novo e-mail (backend devolve
                        // o e-mail confirmado; fallback = o que foi digitado).
                        final novoEmail = (resp['email'] ??
                                emailController.text.trim())
                            .toString();
                        final atual = await SessionService().obterUsuario();
                        if (atual != null) {
                          await SessionService().salvarUsuario(UsuarioLogado(
                            id: atual.id,
                            nome: atual.nome,
                            email: novoEmail,
                            tipo: atual.tipo,
                          ));
                        }
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        AppSnackbar.sucesso(
                            context, 'E-mail alterado com sucesso! 💚');
                      } catch (e) {
                        setStateDialog(() => salvando = false);
                        if (!dialogContext.mounted) return;
                        AppSnackbar.erro(
                            dialogContext, ApiService.mensagemAmigavel(e));
                      }
                    },
              child: Text(salvando ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );

    emailController.dispose();
    senhaController.dispose();
  }
}
