import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../doador/main_shell.dart';
import '../utils/formatters.dart';
import '../services/auth_service.dart';
import '../services/login_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/page_transition.dart';
import '../widgets/buttons/app_button.dart';
import '../widgets/feedback/app_snackbar.dart';
import '../widgets/inputs/app_text_field.dart';

/// Cadastro do doador em MULTI-PASSO (estilo Instagram: um foco por tela,
/// barra de progresso e navegação Voltar/Continuar):
///   1. Identidade (nome + email)
///   2. Senha (com confirmação)
///   3. Localização (cidade/estado/telefone — opcionais)
/// Ao criar a conta (`POST /usuarios/registro`), faz o login automaticamente e
/// entra direto no [MainShell].
class CadastroDoadorPage extends StatefulWidget {
  const CadastroDoadorPage({super.key});

  @override
  State<CadastroDoadorPage> createState() => _CadastroDoadorPageState();
}

class _CadastroDoadorPageState extends State<CadastroDoadorPage> {
  static const int _totalPassos = 3;

  final _pageController = PageController();

  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmarSenha = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();
  final _telefone = TextEditingController();

  int _passo = 0;
  bool _criando = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmarSenha.dispose();
    _cidade.dispose();
    _estado.dispose();
    _telefone.dispose();
    super.dispose();
  }

  bool get _emailValido =>
      RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(_email.text.trim());

  // Valida o passo atual antes de avançar; retorna a mensagem de erro ou null.
  String? _validarPassoAtual() {
    switch (_passo) {
      case 0:
        if (_nome.text.trim().isEmpty) return 'Informe seu nome.';
        if (!_emailValido) return 'Informe um e-mail válido.';
        return null;
      case 1:
        if (_senha.text.length < 6) {
          return 'A senha precisa de pelo menos 6 caracteres.';
        }
        if (_senha.text != _confirmarSenha.text) {
          return 'As senhas não conferem.';
        }
        return null;
      default:
        return null; // passo 3 é todo opcional
    }
  }

  void _avancar() {
    final erro = _validarPassoAtual();
    if (erro != null) {
      AppSnackbar.erro(context, erro);
      return;
    }
    if (_passo < _totalPassos - 1) {
      setState(() => _passo++);
      _pageController.animateToPage(
        _passo,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _criarConta();
    }
  }

  void _voltar() {
    if (_passo == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _passo--);
    _pageController.animateToPage(
      _passo,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _criarConta() async {
    setState(() => _criando = true);
    try {
      await AuthService().registrar(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        senha: _senha.text,
        telefone: _telefone.text.trim(),
        cidade: _cidade.text.trim(),
        estado: _estado.text.trim(),
      );

      // Conta criada: entra direto (login automático como doador).
      await LoginService().fazerLogin(
        email: _email.text.trim(),
        senha: _senha.text,
        tipoSelecionado: 0,
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageTransition.fade(const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _criando = false);
      AppSnackbar.erro(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ultimoPasso = _passo == _totalPassos - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: _criando ? null : _voltar,
        ),
        title: const Text('Criar conta'),
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
                      _passoIdentidade(),
                      _passoSenha(),
                      _passoLocalizacao(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    texto: ultimoPasso ? 'Criar conta' : 'Continuar',
                    carregando: _criando,
                    onPressed: _avancar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Passo 1: nome + email ----
  Widget _passoIdentidade() {
    return _passoBase(
      icone: Icons.waving_hand_outlined,
      titulo: 'Como você se chama?',
      subtitulo: 'Seu nome aparece para as ONGs quando vocês dão match.',
      campos: [
        AppTextField(
          controller: _nome,
          hint: 'Nome completo',
          icon: Icons.person_outline,
          maxLength: 80,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _email,
          hint: 'E-mail',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          maxLength: 120,
        ),
      ],
    );
  }

  // ---- Passo 2: senha ----
  Widget _passoSenha() {
    return _passoBase(
      icone: Icons.lock_outline,
      titulo: 'Crie uma senha',
      subtitulo: 'Use pelo menos 6 caracteres.',
      campos: [
        AppTextField(
          controller: _senha,
          hint: 'Senha',
          icon: Icons.lock_outline,
          obscureText: true,
          maxLength: 60,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _confirmarSenha,
          hint: 'Confirmar senha',
          icon: Icons.lock_reset_outlined,
          obscureText: true,
          maxLength: 60,
        ),
      ],
    );
  }

  // ---- Passo 3: localização (opcional) ----
  Widget _passoLocalizacao() {
    return _passoBase(
      icone: Icons.location_on_outlined,
      titulo: 'Onde você está?',
      subtitulo:
          'Opcional — usamos sua cidade para destacar necessidades perto de você.',
      campos: [
        AppTextField(
          controller: _cidade,
          hint: 'Cidade',
          icon: Icons.location_city_outlined,
          maxLength: 60,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _estado,
          hint: 'Estado (UF)',
          icon: Icons.map_outlined,
          maxLength: 2,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
            UpperCaseTextFormatter(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _telefone,
          hint: 'Telefone (opcional)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          maxLength: 20,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d()\-+ ]')),
          ],
        ),
      ],
    );
  }

  // Layout comum dos passos: ícone em destaque + título + subtítulo + campos.
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
