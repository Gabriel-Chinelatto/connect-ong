import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/inputs/app_text_field.dart';

/// Recuperação de senha em 2 passos (mesmo padrão multi-passo do cadastro):
///   1. Informar o e-mail  -> `POST /auth/esqueci-senha` (envia o código)
///   2. Código de 6 dígitos + nova senha -> `POST /auth/redefinir-senha`
///
/// Quando o backend está em modo demonstração, a resposta do passo 1 traz o
/// campo `codigoDemo`; nesse caso o código é exibido num card destacado
/// (em produção ele iria por e-mail).
class EsqueciSenhaPage extends StatefulWidget {
  /// E-mail pré-preenchido (vindo do campo da tela de login, se digitado).
  final String? emailInicial;

  const EsqueciSenhaPage({super.key, this.emailInicial});

  @override
  State<EsqueciSenhaPage> createState() => _EsqueciSenhaPageState();
}

class _EsqueciSenhaPageState extends State<EsqueciSenhaPage> {
  static const int _totalPassos = 2;

  final _pageController = PageController();

  late final TextEditingController _email =
      TextEditingController(text: widget.emailInicial ?? '');
  final _codigo = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmarSenha = TextEditingController();

  int _passo = 0;
  bool _enviando = false; // guarda anti-duplo-toque (padrão do app)

  // Código exibido quando o servidor está em modo demonstração.
  String? _codigoDemo;

  @override
  void dispose() {
    _pageController.dispose();
    _email.dispose();
    _codigo.dispose();
    _novaSenha.dispose();
    _confirmarSenha.dispose();
    super.dispose();
  }

  bool get _emailValido =>
      RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(_email.text.trim());

  void _irParaPasso(int passo) {
    setState(() => _passo = passo);
    _pageController.animateToPage(
      passo,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _voltar() {
    if (_enviando) return;
    if (_passo == 0) {
      Navigator.pop(context);
      return;
    }
    _irParaPasso(_passo - 1);
  }

  // ---- Passo 1: pedir o código por e-mail ----
  Future<void> _enviarCodigo({bool reenvio = false}) async {
    if (_enviando) return;
    if (!_emailValido) {
      AppSnackbar.erro(context, 'Informe um e-mail válido.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      final resposta =
          await AuthService().esqueciSenha(email: _email.text.trim());
      if (!mounted) return;

      setState(() {
        _codigoDemo = resposta['codigoDemo']?.toString();
      });

      AppSnackbar.sucesso(
        context,
        resposta['mensagem']?.toString() ??
            'Se o e-mail estiver cadastrado, enviamos um código de redefinição.',
      );
      if (!reenvio) _irParaPasso(1);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ---- Passo 2: validar código + definir a nova senha ----
  Future<void> _redefinirSenha() async {
    if (_enviando) return;

    final codigo = _codigo.text.trim();
    if (codigo.length != 6) {
      AppSnackbar.erro(context, 'Digite o código de 6 dígitos.');
      return;
    }
    if (_novaSenha.text.length < 6) {
      AppSnackbar.erro(
          context, 'A nova senha precisa de pelo menos 6 caracteres.');
      return;
    }
    if (_novaSenha.text != _confirmarSenha.text) {
      AppSnackbar.erro(context, 'As senhas não conferem.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      await AuthService().redefinirSenha(
        email: _email.text.trim(),
        codigo: codigo,
        novaSenha: _novaSenha.text,
      );
      if (!mounted) return;

      // Sucesso: volta ao login para entrar com a nova senha.
      AppSnackbar.sucesso(
          context, 'Senha redefinida com sucesso! Entre com a nova senha.');
      Navigator.pop(context);
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
          onPressed: _enviando ? null : _voltar,
        ),
        title: const Text('Recuperar senha'),
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
                // Barra de progresso do fluxo (passo atual / total).
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: ClipRRect(
                    borderRadius: AppRadius.brSm,
                    child: LinearProgressIndicator(
                      value: (_passo + 1) / _totalPassos,
                      minHeight: 6,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _passoEmail(),
                      _passoCodigoESenha(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    texto:
                        _passo == 0 ? 'Enviar código' : 'Redefinir senha',
                    carregando: _enviando,
                    onPressed: () =>
                        _passo == 0 ? _enviarCodigo() : _redefinirSenha(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Passo 1: e-mail ----
  Widget _passoEmail() {
    return _passoBase(
      icone: Icons.lock_reset_outlined,
      titulo: 'Esqueceu a senha?',
      subtitulo:
          'Informe o e-mail da sua conta. Enviaremos um código de 6 dígitos '
          'para você criar uma nova senha.',
      campos: [
        AppTextField(
          controller: _email,
          hint: 'E-mail',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          maxLength: 120,
          onSubmitted: (_) => _enviarCodigo(),
        ),
      ],
    );
  }

  // ---- Passo 2: código + nova senha ----
  Widget _passoCodigoESenha() {
    final cs = Theme.of(context).colorScheme;
    return _passoBase(
      icone: Icons.password_outlined,
      titulo: 'Digite o código',
      subtitulo:
          'Enviamos um código de 6 dígitos para ${_email.text.trim()}. '
          'Digite-o abaixo e crie sua nova senha.',
      campos: [
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
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _novaSenha,
          hint: 'Nova senha (mín. 6 caracteres)',
          icon: Icons.lock_outline,
          obscureText: true,
          maxLength: 60,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _confirmarSenha,
          hint: 'Confirmar nova senha',
          icon: Icons.lock_reset_outlined,
          obscureText: true,
          maxLength: 60,
          onSubmitted: (_) => _redefinirSenha(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _enviando ? null : () => _enviarCodigo(reenvio: true),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reenviar código'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
        Text(
          'Não recebeu? Verifique a caixa de spam ou toque em "Reenviar código".',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  // Card destacado do MODO DEMONSTRAÇÃO: mostra o código na tela porque o
  // servidor de demonstração não envia e-mails de verdade.
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
              Icon(Icons.science_outlined,
                  size: 18, color: AppColors.primary),
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

  // Layout comum dos passos (mesmo padrão do cadastro multi-passo).
  Widget _passoBase({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required List<Widget> campos,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
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
            child: Icon(icone, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitulo,
            style: TextStyle(
                fontSize: 14, color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...campos,
        ],
      ),
    );
  }
}
