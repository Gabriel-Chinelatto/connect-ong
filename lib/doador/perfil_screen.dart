import 'package:flutter/material.dart';

import '../services/perfil_service.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';

import '../config/config_controller.dart';
import '../pages/login_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/page_transition.dart';
import '../widgets/feedback/app_snackbar.dart';

/// Perfil do doador: edita dados pessoais (nome, telefone, cidade, estado, bio,
/// foto) e exibe um resumo do impacto (total de matches e ONGs apoiadas).
///
/// Redesenho (Bloco 21 / Fase 4): design system + cores do TEMA (dark mode ok)
/// e botao de sair (logout) movido para ca.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final PerfilService _perfilService = PerfilService();
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();
  final _bio = TextEditingController();
  final _fotoUrl = TextEditingController();

  int? _usuarioId;
  String _email = '';
  bool _carregando = true;
  bool _salvando = false;

  int _matches = 0;
  int _ongs = 0;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _cidade.dispose();
    _estado.dispose();
    _bio.dispose();
    _fotoUrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final u = await _sessionService.obterUsuario();
      if (u == null) {
        if (mounted) setState(() => _carregando = false);
        return;
      }
      _usuarioId = u.id;
      final perfil = await _perfilService.obter(u.id);
      final matches = await _interesseService.meusMatches(u.id);
      final aceitos = matches.where((m) => m.status == 'ACEITO').toList();
      if (!mounted) return;
      setState(() {
        _email = perfil['email'] ?? '';
        _nome.text = perfil['nome'] ?? '';
        _telefone.text = perfil['telefone'] ?? '';
        _cidade.text = perfil['cidade'] ?? '';
        _estado.text = perfil['estado'] ?? '';
        _bio.text = perfil['bio'] ?? '';
        _fotoUrl.text = perfil['fotoUrl'] ?? '';
        _matches = aceitos.length;
        _ongs = aceitos
            .map((m) => m.ongNome)
            .where((n) => n != null)
            .toSet()
            .length;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String get _nivel {
    if (_matches >= 3) return 'Embaixador';
    if (_matches >= 1) return 'Engajado';
    return 'Iniciante';
  }

  Future<void> _salvar() async {
    if (_usuarioId == null) return;
    setState(() => _salvando = true);
    try {
      await _perfilService.atualizar(_usuarioId!, {
        'nome': _nome.text.trim(),
        'telefone': _telefone.text.trim(),
        'cidade': _cidade.text.trim(),
        'estado': _estado.text.trim(),
        'bio': _bio.text.trim(),
        'fotoUrl': _fotoUrl.text.trim(),
      });
      if (!mounted) return;
      setState(() => _salvando = false);
      AppSnackbar.sucesso(context, 'Perfil atualizado! 💚');
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      AppSnackbar.erro(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logout() async {
    await _sessionService.logout();
    ConfigController.instance.limpar();
    if (!mounted) return;
    Navigator.pushReplacement(context, PageTransition.fade(const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iniciais = _nome.text.isNotEmpty ? _nome.text[0].toUpperCase() : '?';
    final foto = _fotoUrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.primary,
                    backgroundImage:
                        foto.isNotEmpty ? NetworkImage(foto) : null,
                    child: foto.isEmpty
                        ? Text(iniciais,
                            style: const TextStyle(
                                fontSize: 40, color: Colors.white))
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(_email,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _statMini('$_matches', 'Matches', Icons.handshake),
                    const SizedBox(width: AppSpacing.sm),
                    _statMini('$_ongs', 'ONGs', Icons.favorite),
                    const SizedBox(width: AppSpacing.sm),
                    _statMini(_nivel, 'Nível', Icons.star),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _campo(_nome, 'Nome'),
                _campo(_telefone, 'Telefone'),
                _campo(_cidade, 'Cidade'),
                _campo(_estado, 'Estado'),
                _campo(_bio, 'Bio', linhas: 3),
                _campo(_fotoUrl, 'URL da foto (opcional)'),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Salvar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.brLg),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statMini(String valor, String rotulo, IconData icone) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: AppRadius.brLg,
        ),
        child: Column(
          children: [
            Icon(icone, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(valor,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: cs.onSurface)),
            Text(rotulo,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, {int linhas = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: c,
        maxLines: linhas,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
