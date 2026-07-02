import 'package:flutter/material.dart';

import '../config/config_controller.dart';
import '../models/preferencia.dart';
import '../pages/login_page.dart';
import '../services/api_service.dart';
import '../services/perfil_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../utils/page_transition.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../screens/legal/documentos_legais_screen.dart';

/// Central de configuracoes do doador: aparencia (tema/fonte), notificacoes,
/// privacidade, seguranca e acessibilidade. Mudancas de aparencia sao aplicadas
/// na hora e persistidas pelo ConfigController.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  late Preferencia _p;
  int? _usuarioId;
  bool _excluindo = false;

  @override
  void initState() {
    super.initState();
    _p = ConfigController.instance.prefs.copy();
    SessionService().obterUsuario().then((u) {
      if (mounted) setState(() => _usuarioId = u?.id);
    });
  }

  // Aplica + persiste (a aparencia muda o app na hora).
  void _aplicar() {
    setState(() {});
    ConfigController.instance.atualizar(_p.copy());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _secao('Aparência', Icons.palette_outlined),
          _escolha(
            'Tema',
            const ['CLARO', 'ESCURO', 'AUTOMATICO'],
            const ['Claro', 'Escuro', 'Automático'],
            _p.tema,
            (v) {
              _p.tema = v;
              _aplicar();
            },
          ),
          _escolha(
            'Tamanho da fonte',
            const ['PEQUENA', 'MEDIA', 'GRANDE'],
            const ['Pequena', 'Média', 'Grande'],
            _p.tamanhoFonte,
            (v) {
              _p.tamanhoFonte = v;
              _aplicar();
            },
          ),
          _switch('Alto contraste', 'Mais contraste para leitura',
              _p.altoContraste, (v) {
            _p.altoContraste = v;
            _aplicar();
          }),
          _switch('Fonte para dislexia', 'Usa uma fonte mais legível',
              _p.fonteDislexia, (v) {
            _p.fonteDislexia = v;
            _aplicar();
          }),
          _switch('Navegação simplificada', 'Modo mais simples de usar',
              _p.navegacaoSimplificada, (v) {
            _p.navegacaoSimplificada = v;
            _aplicar();
          }),

          _secao('Notificações', Icons.notifications_outlined),
          _switch('Novas mensagens', null, _p.notifMensagens, (v) {
            _p.notifMensagens = v;
            _aplicar();
          }),
          _switch('Match de doações', null, _p.notifMatch, (v) {
            _p.notifMatch = v;
            _aplicar();
          }),
          _switch('Atualizações de campanhas', null, _p.notifCampanhas, (v) {
            _p.notifCampanhas = v;
            _aplicar();
          }),
          _switch('Novas necessidades', null, _p.notifNecessidades, (v) {
            _p.notifNecessidades = v;
            _aplicar();
          }),
          _switch('Notícias da plataforma', null, _p.notifNoticias, (v) {
            _p.notifNoticias = v;
            _aplicar();
          }),

          _secao('Privacidade', Icons.lock_outline),
          _switch('Exibir telefone', null, _p.mostrarTelefone, (v) {
            _p.mostrarTelefone = v;
            _aplicar();
          }),
          _switch('Exibir e-mail', null, _p.mostrarEmail, (v) {
            _p.mostrarEmail = v;
            _aplicar();
          }),
          _switch('Perfil público', null, _p.perfilPublico, (v) {
            _p.perfilPublico = v;
            _aplicar();
          }),
          _switch('Receber contatos de ONGs', null, _p.receberContatos, (v) {
            _p.receberContatos = v;
            _aplicar();
          }),
          _switch('Receber sugestões', null, _p.receberSugestoes, (v) {
            _p.receberSugestoes = v;
            _aplicar();
          }),

          _secao('Segurança', Icons.shield_outlined),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Alterar senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _abrirAlterarSenha,
          ),

          _secao('Apresentação', Icons.storefront_outlined),
          _switch(
            'Modo Feira',
            'Mostra as credenciais de demonstração na tela de login',
            ConfigController.instance.modoFeira,
            (v) {
              ConfigController.instance.definirModoFeira(v);
              setState(() {});
            },
          ),

          _secao('Termos e Privacidade', Icons.gavel_outlined),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _abrirDocumento(DocumentoLegal.privacidade),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Termos de Uso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _abrirDocumento(DocumentoLegal.termos),
          ),

          // Zona de perigo: acao destrutiva, destacada em vermelho.
          _secaoPerigo('Zona de perigo', Icons.warning_amber_rounded),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text(
              'Excluir minha conta',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text('Desativa sua conta permanentemente'),
            onTap: _excluindo ? null : _confirmarExcluirConta,
          ),
          const SizedBox(height: 24),
        ],
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

  Widget _secaoPerigo(String titulo, IconData icone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Icon(icone, size: 20, color: AppColors.error),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _secao(String titulo, IconData icone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Icon(icone, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(
      String titulo, String? subtitulo, bool valor, ValueChanged<bool> onChange) {
    return SwitchListTile(
      title: Text(titulo),
      subtitle: subtitulo == null ? null : Text(subtitulo),
      value: valor,
      activeThumbColor: AppColors.primary,
      onChanged: onChange,
    );
  }

  Widget _escolha(
    String titulo,
    List<String> valores,
    List<String> rotulos,
    String selecionado,
    ValueChanged<String> onChange,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(titulo),
          ),
          Wrap(
            spacing: 8,
            children: List.generate(valores.length, (i) {
              final sel = valores[i] == selecionado;
              return ChoiceChip(
                label: Text(rotulos[i]),
                selected: sel,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : null,
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
}
