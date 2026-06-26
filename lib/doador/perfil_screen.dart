import 'package:flutter/material.dart';

import '../services/perfil_service.dart';
import '../services/interesse_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';

/// Perfil do doador: edita dados pessoais (nome, telefone, cidade, estado, bio,
/// foto) e exibe um resumo do impacto (total de matches e ONGs apoiadas).
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado! 💚'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iniciais = _nome.text.isNotEmpty ? _nome.text[0].toUpperCase() : '?';
    final foto = _fotoUrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 8),
                Center(
                  child: Text(_email,
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statMini('$_matches', 'Matches', Icons.handshake),
                    const SizedBox(width: 10),
                    _statMini('$_ongs', 'ONGs', Icons.favorite),
                    const SizedBox(width: 10),
                    _statMini(_nivel, 'Nível', Icons.star),
                  ],
                ),
                const SizedBox(height: 24),
                _campo(_nome, 'Nome'),
                _campo(_telefone, 'Telefone'),
                _campo(_cidade, 'Cidade'),
                _campo(_estado, 'Estado'),
                _campo(_bio, 'Bio', linhas: 3),
                _campo(_fotoUrl, 'URL da foto (opcional)'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Salvar'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statMini(String valor, String rotulo, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icone, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(valor,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(rotulo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, {int linhas = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        maxLines: linhas,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
