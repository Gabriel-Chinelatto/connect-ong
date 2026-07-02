import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/perfil_service.dart';
import '../services/session_service.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';
import '../widgets/feedback/app_snackbar.dart';

/// Edicao dos dados pessoais do doador (nome, telefone, cidade, estado, bio e
/// foto de perfil via galeria). Separada da aba Perfil (que virou um hub de
/// navegacao) para manter cada tela com uma unica responsabilidade.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final PerfilService _perfilService = PerfilService();
  final SessionService _sessionService = SessionService();

  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();
  final _bio = TextEditingController();
  final _fotoUrl = TextEditingController();

  int? _usuarioId;
  bool _carregando = true;
  bool _salvando = false;

  // Foto escolhida da galeria (base64) e seus bytes decodificados p/ exibir.
  String _fotoBase64 = '';
  Uint8List? _fotoBytes;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

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

  Future<void> _carregar() async {
    try {
      final u = await _sessionService.obterUsuario();
      if (u == null) {
        if (mounted) setState(() => _carregando = false);
        return;
      }
      _usuarioId = u.id;
      final perfil = await _perfilService.obter(u.id);
      if (!mounted) return;
      setState(() {
        _nome.text = perfil['nome'] ?? '';
        _telefone.text = perfil['telefone'] ?? '';
        _cidade.text = perfil['cidade'] ?? '';
        _estado.text = perfil['estado'] ?? '';
        _bio.text = perfil['bio'] ?? '';
        _fotoUrl.text = perfil['fotoUrl'] ?? '';
        _fotoBase64 = perfil['fotoBase64'] ?? '';
        _fotoBytes =
            _fotoBase64.isNotEmpty ? base64Decode(_fotoBase64) : null;
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (_usuarioId == null) return;
    // Nome é obrigatório — não deixa salvar em branco por cima do dado real.
    if (_nome.text.trim().isEmpty) {
      AppSnackbar.erro(context, 'Informe seu nome.');
      return;
    }
    setState(() => _salvando = true);
    try {
      await _perfilService.atualizar(_usuarioId!, {
        'nome': _nome.text.trim(),
        'telefone': _telefone.text.trim(),
        'cidade': _cidade.text.trim(),
        'estado': _estado.text.trim(),
        'bio': _bio.text.trim(),
        'fotoUrl': _fotoUrl.text.trim(),
        'fotoBase64': _fotoBase64,
      });
      if (!mounted) return;
      setState(() => _salvando = false);
      AppSnackbar.sucesso(context, 'Perfil atualizado! 💚');
      Navigator.pop(context, true); // avisa o hub para recarregar
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      AppSnackbar.erro(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Abre a galeria, escolhe uma imagem (reduzida) e a guarda como base64.
  Future<void> _escolherFoto() async {
    final XFile? img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fotoBytes = bytes;
      _fotoBase64 = base64Encode(bytes);
    });
  }

  // Imagem do avatar: prioriza a foto da galeria (base64); depois a URL antiga.
  ImageProvider? _avatarImagem() {
    if (_fotoBytes != null) return MemoryImage(_fotoBytes!);
    final url = _fotoUrl.text.trim();
    if (url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iniciais = _nome.text.isNotEmpty ? _nome.text[0].toUpperCase() : '?';
    final avatarImg = _avatarImagem();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
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
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primary,
                        backgroundImage: avatarImg,
                        child: avatarImg == null
                            ? Text(iniciais,
                                style: const TextStyle(
                                    fontSize: 40, color: AppColors.onPrimary))
                            : null,
                      ),
                      TextButton.icon(
                        onPressed: _escolherFoto,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('Trocar foto'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _campo(_nome, 'Nome', maxLength: 80),
                _campo(_telefone, 'Telefone',
                    keyboardType: TextInputType.phone,
                    maxLength: 20,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d()\-+ ]')),
                    ]),
                _campo(_cidade, 'Cidade', maxLength: 60),
                _campo(_estado, 'Estado (UF)',
                    maxLength: 2,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                      UpperCaseTextFormatter(),
                    ]),
                _campo(_bio, 'Bio', linhas: 3, maxLength: 200),
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
                                color: AppColors.onPrimary, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Salvar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    int linhas = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: c,
        maxLines: linhas,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
        ),
      ),
    );
  }
}
