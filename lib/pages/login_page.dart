import 'dart:async';

import 'package:flutter/material.dart';

import '../doador/main_shell.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

import '../services/api_service.dart';
import '../services/login_service.dart';
import '../config/config_controller.dart';

import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';

import '../utils/page_transition.dart';
import '../web/portal_institucional_screen.dart';
import 'cadastro_doador_page.dart';
import 'esqueci_senha_page.dart';
import 'verificacao_2fa_page.dart';

/// Tela de login do doador (porta de entrada do app mobile).
///
/// Redesenho visual (12/08/2026): a tela era clara demais no topo (texto branco
/// sobre verde-claro ficava lavado) e repetia os NÚMEROS da plataforma que o
/// portal institucional — a tela ANTERIOR ao login — já mostra, e lá com o valor
/// formatado. Os números saíram daqui; ficou o herói (marca + frase que alterna)
/// sobre um fundo em degradê profundo com brilhos suaves, e o formulário num
/// cartão branco flutuante. Nenhum comportamento mudou: os mesmos campos, os
/// mesmos destinos e o mesmo fluxo de login/2FA.
///
/// A tela é sempre clara (padrão de telas de autenticação), evitando problemas
/// de contraste no modo escuro.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  // Focos: servem só para o realce visual do campo ativo (borda verde, ícone
  // colorido e sombra). Não alteram a navegação por teclado.
  final FocusNode _focoEmail = FocusNode();
  final FocusNode _focoSenha = FocusNode();

  final LoginService _loginService = LoginService();

  // Credenciais de demonstração exibidas no "Modo Feira" (ex.: FECITEC).
  static const String _demoEmail = 'demo.joao@connectong.com';
  static const String _demoSenha = 'demo123';

  bool carregando = false;

  // Degradê do fundo. Começa num verde vivo e fecha no verde escuro da marca:
  // dá profundidade e garante contraste do texto branco em toda a coluna.
  static const LinearGradient _fundo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12A85E), AppColors.primary, AppColors.primaryDark],
    stops: [0.0, 0.5, 1.0],
  );

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
    // Alterna a frase de impacto a cada 4s (efeito "onboarding vivo").
    _fraseTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _fraseAtual = (_fraseAtual + 1) % _frases.length);
    });
    _focoEmail.addListener(_repintar);
    _focoSenha.addListener(_repintar);
  }

  void _repintar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fraseTimer?.cancel();
    _focoEmail.removeListener(_repintar);
    _focoSenha.removeListener(_repintar);
    _focoEmail.dispose();
    _focoSenha.dispose();
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
      final resultado = await _loginService.fazerLogin(
        email: email,
        senha: senha,
        tipoSelecionado: 0, // app mobile é exclusivo do doador
      );
      if (!mounted) return;

      // Verificação em duas etapas: em vez do token, o backend pediu um código.
      // Segue para a tela de confirmação (que finaliza o login).
      if (resultado.requer2fa) {
        Navigator.push(
          context,
          PageTransition.fade(
            Verificacao2faPage(
              email: resultado.email ?? email,
              senha: senha,
              codigoDemo: resultado.codigoDemo,
            ),
          ),
        );
        return;
      }

      final usuario = resultado.usuario!;
      await ConfigController.instance.carregar(usuario.id);
      if (!mounted) return;

      AppSnackbar.sucesso(context, 'Login realizado com sucesso!');
      Navigator.pushReplacement(
        context,
        PageTransition.fade(const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      // mensagemAmigavel: sem isto o usuário via o erro cru
      // ("TimeoutException after 0:00:12: Future not completed").
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
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
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _fundo),
        child: Stack(
          children: [
            ..._brilhos(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, restricoes) {
                  // Centraliza de verdade quando sobra altura e rola quando o
                  // teclado ou uma tela baixa apertam o conteúdo.
                  final alturaMinima =
                      (restricoes.maxHeight - AppSpacing.xl * 2)
                          .clamp(0.0, double.infinity);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: alturaMinima),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _heroi(),
                              const SizedBox(height: AppSpacing.xl),
                              _cardFormulario(),
                              if (ConfigController.instance.modoFeira) ...[
                                const SizedBox(height: AppSpacing.md),
                                _cardModoFeira(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Brilhos decorativos do fundo ----
  // Círculos translúcidos que quebram a chapa do degradê. `IgnorePointer` para
  // que jamais roubem um toque do formulário.
  List<Widget> _brilhos() => [
        Positioned(
          top: -90,
          right: -70,
          child: _bolha(240, Colors.white.withValues(alpha: 0.10)),
        ),
        Positioned(
          top: 140,
          left: -120,
          child: _bolha(230, AppColors.primaryLight.withValues(alpha: 0.16)),
        ),
        Positioned(
          bottom: -130,
          right: -80,
          child: _bolha(300, Colors.white.withValues(alpha: 0.06)),
        ),
      ];

  Widget _bolha(double diametro, Color cor) => IgnorePointer(
        child: Container(
          width: diametro,
          height: diametro,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
      );

  // ---- Herói: marca + frase de impacto que alterna ----
  Widget _heroi() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          // O emblema já é redondo: o recorte oval esconde os cantos brancos
          // do JPG e deixa a moldura perfeitamente circular.
          child: ClipOval(
            child: Container(
              width: 112,
              height: 112,
              color: Colors.white,
              alignment: Alignment.center,
              // O JPG é 500x500 com margem branca; preencher o círculo inteiro
              // (em vez de caber dentro dele) faz o emblema ganhar corpo — como
              // ele já é redondo e o fundo é branco, o recorte não some com nada.
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 122,
                height: 122,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Connect ONG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Frase de impacto que troca com um leve deslize para cima.
        SizedBox(
          height: 28,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (filho, animacao) => FadeTransition(
              opacity: animacao,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(animacao),
                child: filho,
              ),
            ),
            child: Text(
              _frases[_fraseAtual],
              key: ValueKey(_fraseAtual),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Card do formulário (sempre claro) ----
  Widget _cardFormulario() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.brXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.30),
            blurRadius: 40,
            spreadRadius: -8,
            offset: const Offset(0, 18),
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
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Entre para continuar ajudando quem precisa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _campo(
            controller: emailController,
            foco: _focoEmail,
            hint: 'E-mail',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          _campo(
            controller: senhaController,
            foco: _focoSenha,
            hint: 'Senha',
            icon: Icons.lock_outline_rounded,
            obscure: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => fazerLogin(), // Enter entra
          ),
          // Link de recuperação de senha (fluxo em 2 passos).
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                PageTransition.fade(
                  EsqueciSenhaPage(emailInicial: emailController.text.trim()),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Esqueceu a senha?'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            texto: 'ENTRAR',
            carregando: carregando,
            onPressed: fazerLogin,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(
            color: AppColors.divider,
            thickness: 1,
            height: AppSpacing.md,
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              PageTransition.fade(const CadastroDoadorPage()),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
            child: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Não tem conta?  ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextSpan(
                    text: 'Cadastre-se',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 14.5),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PortalInstitucionalScreen(),
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            ),
            icon: const Icon(Icons.info_outline_rounded, size: 17),
            label: const Text('Sobre o Projeto'),
          ),
        ],
      ),
    );
  }

  // ---- Card "Modo Feira": credenciais de demonstração (só quando ligado) ----
  // Discreto, abaixo do formulário: vidro translúcido sobre o verde, para não
  // competir com o cartão branco do login. Mostra e-mail/senha demo legíveis e
  // um botão que preenche os campos. Controlado pela flag em Configurações.
  Widget _cardModoFeira() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Modo Feira — acesso de demonstração',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
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
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                ),
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
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Campo de texto sempre claro (independe do tema), para o card branco.
  // Ganha borda verde, ícone colorido e um halo suave quando está em foco.
  Widget _campo({
    required TextEditingController controller,
    required FocusNode foco,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    final bool ativo = foco.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        boxShadow: ativo
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: TextField(
        controller: controller,
        focusNode: foco,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: ativo ? AppColors.primary : AppColors.textTertiary,
          ),
          filled: true,
          fillColor: ativo ? Colors.white : AppColors.surfaceMuted,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          border: const OutlineInputBorder(
            borderRadius: AppRadius.brLg,
            borderSide: BorderSide(color: AppColors.border, width: 1.2),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.brLg,
            borderSide: BorderSide(color: AppColors.border, width: 1.2),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.brLg,
            borderSide: BorderSide(color: AppColors.primary, width: 1.8),
          ),
        ),
      ),
    );
  }
}
