import 'dart:async';

import 'package:flutter/material.dart';

import '../doador/main_shell.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

import '../services/login_service.dart';
import '../services/estatistica_service.dart';
import '../config/config_controller.dart';

import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';

import '../utils/page_transition.dart';
import '../web/portal_institucional_screen.dart';
import 'cadastro_doador_page.dart';

/// Tela de login do doador (porta de entrada do app mobile).
///
/// Redesenho (Bloco 21 / Fase 2), inspirado em telas de onboarding modernas:
/// um "herói" com a marca + uma frase de impacto que alterna + os NÚMEROS REAIS
/// da plataforma (prova social vinda de GET /publico/estatisticas), seguido do
/// formulário de acesso. A tela é sempre clara (padrão de telas de autenticação),
/// evitando problemas de contraste no modo escuro.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  final LoginService _loginService = LoginService();

  // Credenciais de demonstração exibidas no "Modo Feira" (ex.: FECITEC).
  static const String _demoEmail = 'demo.joao@connectong.com';
  static const String _demoSenha = 'demo123';

  bool carregando = false;

  // Números reais da plataforma (prova social). Opcional: se a API não
  // responder, a tela funciona igual, só não mostra os números.
  EstatisticasPublicas? _stats;

  // Frases de impacto que alternam no herói.
  static const List<String> _frases = [
    'Conecte-se a quem precisa.',
    'Sua doação vira história.',
    'Transparência que gera impacto real.',
  ];
  int _fraseAtual = 0;
  Timer? _fraseTimer;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
    // Alterna a frase de impacto a cada 4s (efeito "onboarding vivo").
    _fraseTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _fraseAtual = (_fraseAtual + 1) % _frases.length);
    });
  }

  Future<void> _carregarEstatisticas() async {
    try {
      final s = await EstatisticaService().carregar();
      if (!mounted) return;
      setState(() => _stats = s);
    } catch (_) {
      // Silencioso: os números são um complemento, não bloqueiam o login.
    }
  }

  @override
  void dispose() {
    _fraseTimer?.cancel();
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> fazerLogin() async {
    // Validação local antes de gastar um round-trip na API.
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();
    if (email.isEmpty || senha.isEmpty) {
      AppSnackbar.erro(context, 'Preencha e-mail e senha para entrar.');
      return;
    }
    if (carregando) return; // guarda contra toque duplo

    FocusScope.of(context).unfocus();
    setState(() => carregando = true);

    try {
      final usuario = await _loginService.fazerLogin(
        email: email,
        senha: senha,
        tipoSelecionado: 0, // app mobile é exclusivo do doador
      );

      await ConfigController.instance.carregar(usuario.id);
      if (!mounted) return;

      AppSnackbar.sucesso(context, 'Login realizado com sucesso!');
      Navigator.pushReplacement(
        context,
        PageTransition.fade(const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  // Preenche o formulário com as credenciais demo (Modo Feira).
  void _preencherDemo() {
    emailController.text = _demoEmail;
    senhaController.text = _demoSenha;
    AppSnackbar.sucesso(context, 'Credenciais de demonstração preenchidas.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    _heroi(),
                    const SizedBox(height: AppSpacing.xl),
                    _cardFormulario(),
                    if (ConfigController.instance.modoFeira) ...[
                      const SizedBox(height: AppSpacing.md),
                      _cardModoFeira(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Herói: logo + frase de impacto que alterna + números reais ----
  Widget _heroi() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.brXl,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset('assets/images/logo.jpg', height: 84),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Connect ONG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Frase de impacto que troca suavemente.
        SizedBox(
          height: 30,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: Text(
              _frases[_fraseAtual],
              key: ValueKey(_fraseAtual),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (_stats != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _numerosReais(_stats!),
        ],
      ],
    );
  }

  Widget _numerosReais(EstatisticasPublicas s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _numero('${s.totalOngs}', 'ONGs'),
        _divisor(),
        _numero('R\$ ${s.valorTotalDoado.toStringAsFixed(0)}', 'doados'),
        _divisor(),
        _numero('${s.totalNecessidades}', 'causas'),
      ],
    );
  }

  Widget _numero(String valor, String rotulo) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          rotulo,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _divisor() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.35),
      );

  // ---- Card do formulário (sempre claro) ----
  Widget _cardFormulario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.brXl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Acesso do doador',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _campo(
            controller: emailController,
            hint: 'E-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          _campo(
            controller: senhaController,
            hint: 'Senha',
            icon: Icons.lock_outline,
            obscure: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => fazerLogin(), // Enter entra
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            texto: 'ENTRAR',
            carregando: carregando,
            onPressed: fazerLogin,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              PageTransition.fade(const CadastroDoadorPage()),
            ),
            child: const Text('Não tem conta? Cadastre-se'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PortalInstitucionalScreen(),
              ),
            ),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Sobre o Projeto'),
          ),
        ],
      ),
    );
  }

  // ---- Card "Modo Feira": credenciais de demonstração (só quando ligado) ----
  // Discreto, abaixo do formulário. Mostra e-mail/senha demo legíveis e um
  // botão que preenche os campos. Controlado pela flag local em Configurações.
  Widget _cardModoFeira() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.primaryLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Modo Feira — acesso de demonstração',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _linhaCredencial('E-mail', _demoEmail),
          const SizedBox(height: AppSpacing.xs),
          _linhaCredencial('Senha', _demoSenha),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _preencherDemo,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Preencher'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Linha "rótulo: valor" com o valor selecionável (texto legível/copiável).
  Widget _linhaCredencial(String rotulo, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            rotulo,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            valor,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Campo de texto sempre claro (independe do tema), para o card branco.
  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
