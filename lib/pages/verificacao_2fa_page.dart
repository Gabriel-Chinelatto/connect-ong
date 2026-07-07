import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/config_controller.dart';
import '../doador/main_shell.dart';
import '../services/api_service.dart';
import '../services/login_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/page_transition.dart';
import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/inputs/app_text_field.dart';

/// Segundo passo do login quando a verificação em duas etapas (2FA) está
/// ligada: o backend já enviou um código de 6 dígitos para o e-mail do usuário
/// (`POST /usuarios/login` respondeu `requer2fa: true`). Aqui ele digita o
/// código e conclui o login via `POST /auth/login-2fa`.
///
/// Reaproveita o visual do fluxo "esqueci a senha" (ícone + título + card de
/// modo demonstração quando o servidor devolve `codigoDemo`).
class Verificacao2faPage extends StatefulWidget {
  final String email;

  /// Senha digitada no login — usada apenas para REENVIAR o código (repete o
  /// login, que dispara um novo envio). Não é persistida.
  final String senha;

  /// Código exibido em modo demonstração (em produção iria por e-mail).
  final String? codigoDemo;

  const Verificacao2faPage({
    super.key,
    required this.email,
    required this.senha,
    this.codigoDemo,
  });

  @override
  State<Verificacao2faPage> createState() => _Verificacao2faPageState();
}

class _Verificacao2faPageState extends State<Verificacao2faPage> {
  final LoginService _loginService = LoginService();
  final _codigo = TextEditingController();

  bool _enviando = false; // guarda anti-duplo-toque
  String? _codigoDemo;

  @override
  void initState() {
    super.initState();
    _codigoDemo = widget.codigoDemo;
  }

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_enviando) return;
    final codigo = _codigo.text.trim();
    if (codigo.length != 6) {
      AppSnackbar.erro(context, 'Digite o código de 6 dígitos.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      final usuario = await _loginService.finalizarDoisFatores(
        email: widget.email,
        codigo: codigo,
        tipoSelecionado: 0, // app mobile é exclusivo do doador
      );

      await ConfigController.instance.carregar(usuario.id);
      if (!mounted) return;

      AppSnackbar.sucesso(context, 'Login realizado com sucesso!');
      // Substitui login + esta tela pela shell principal.
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition.fade(const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // Reenvia o código repetindo o login (o backend dispara um novo envio).
  Future<void> _reenviar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      final resultado = await _loginService.fazerLogin(
        email: widget.email,
        senha: widget.senha,
        tipoSelecionado: 0,
      );
      if (!mounted) return;
      if (resultado.requer2fa) {
        setState(() => _codigoDemo = resultado.codigoDemo);
        AppSnackbar.sucesso(context, 'Enviamos um novo código.');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: _enviando ? null : () => Navigator.pop(context),
        ),
        title: const Text('Verificação em duas etapas'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_outlined,
                              color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Confirme que é você',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Enviamos um código de 6 dígitos para ${widget.email}. '
                          'Digite-o abaixo para entrar.',
                          style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                              height: 1.4),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (_codigoDemo != null) ...[
                          _cardCodigoDemo(_codigoDemo!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AppTextField(
                          controller: _codigo,
                          hint: 'Código de 6 dígitos',
                          icon: Icons.pin_outlined,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onSubmitted: (_) => _confirmar(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _enviando ? null : _reenviar,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reenviar código'),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    texto: 'Entrar',
                    carregando: _enviando,
                    onPressed: _confirmar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Card do MODO DEMONSTRAÇÃO: mostra o código na tela porque o servidor de
  // demonstração não envia e-mails de verdade (mesmo padrão do esqueci-senha).
  Widget _cardCodigoDemo(String codigo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Modo demonstração',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            'Seu código é $codigo',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Em produção este código seria enviado para o seu e-mail.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
