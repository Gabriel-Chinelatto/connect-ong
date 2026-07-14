import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/perfil_service.dart';
import '../services/interesse_service.dart';
import '../services/perfil_publico_service.dart';
import '../services/session_service.dart';

import '../config/config_controller.dart';
import '../pages/login_page.dart';
import '../screens/about/descricao_screen.dart';
import '../screens/about/desenvolvimento_chat_screen.dart';
import '../screens/about/integrantes_projeto_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/page_transition.dart';

import 'configuracoes_screen.dart';
import 'conquistas_screen.dart';
import 'editar_perfil_screen.dart';
import 'favoritos_screen.dart';
import 'minhas_doacoes_screen.dart';
import 'notificacoes_screen.dart';
import 'perfil_publico_doador_screen.dart';

/// Aba PERFIL do shell do doador — hub da conta (estilo perfil de app de
/// mercado): avatar + resumo de impacto no topo e, abaixo, o menu com TODAS as
/// funcoes da conta (editar perfil, doacoes, favoritos, conquistas,
/// notificacoes, configuracoes e "sobre o projeto"). Substitui o antigo hub em
/// grade da HomeDoadorScreen.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final PerfilService _perfilService = PerfilService();
  final InteresseService _interesseService = InteresseService();
  final SessionService _sessionService = SessionService();

  bool _carregando = true;

  String _nome = '';
  String _email = '';
  Uint8List? _fotoBytes;

  int _matches = 0;
  int _ongs = 0;

  int? _usuarioId;

  // Reputação do doador (avaliações que as ONGs fizeram dele). Best-effort:
  // se o endpoint público falhar, o hub apenas não mostra as estrelas.
  double _notaMedia = 0;
  int _totalAvaliacoes = 0;

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
      // ACEITO e CONCLUIDO contam como match realizado (mesma regra do
      // dashboard) — sem o CONCLUIDO, os stats zeravam após a conclusão.
      final aceitos = matches
          .where((m) => m.status == 'ACEITO' || m.status == 'CONCLUIDO')
          .toList();

      // Nota média do doador (perfil público) — falha sem quebrar o hub.
      double nota = 0;
      int totalAval = 0;
      try {
        final publico = await PerfilPublicoService().buscarDoador(u.id);
        nota = publico.notaMediaDoador;
        totalAval = publico.totalAvaliacoesDoador;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _nome = perfil['nome'] ?? '';
        _email = perfil['email'] ?? '';
        final fotoBase64 = perfil['fotoBase64'] ?? '';
        _fotoBytes =
            fotoBase64.isNotEmpty ? base64Decode(fotoBase64) : null;
        _notaMedia = nota;
        _totalAvaliacoes = totalAval;
        _matches = aceitos.length;
        _ongs = aceitos
            .map((m) => m.ongNome)
            .where((n) => n != null)
            .toSet()
            .length;
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String get _nivel {
    if (_matches >= 3) return 'Embaixador';
    if (_matches >= 1) return 'Engajado';
    return 'Iniciante';
  }

  // Foto de perfil SEMPRE por arquivo (fotoBase64); sem foto, mostra inicial.
  ImageProvider? _avatarImagem() {
    if (_fotoBytes != null) return MemoryImage(_fotoBytes!);
    return null;
  }

  Future<void> _logout() async {
    // Confirmacao antes de sair (evita logout acidental).
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
            'Você vai precisar entrar de novo para continuar ajudando.'),
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
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    await _sessionService.logout();
    ConfigController.instance.limpar();
    if (!mounted) return;
    Navigator.pushReplacement(context, PageTransition.fade(const LoginPage()));
  }

  Future<void> _abrir(Widget tela) async {
    final resultado =
        await Navigator.push(context, PageTransition.fade(tela));
    // Ao voltar da edicao de perfil (ou de qualquer tela que retorne true),
    // recarrega os dados do topo.
    if (resultado == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // Aba do shell: nunca mostra seta de voltar. Sair do app so pelo
        // botao "Sair" (com confirmacao), como nos apps de rede social.
        automaticallyImplyLeading: false,
        title: const Text('Meu Perfil'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _cabecalho(),
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
                  _secao('Minha conta', [
                    _item(Icons.edit_outlined, 'Editar perfil',
                        () => _abrir(const EditarPerfilScreen())),
                    if (_usuarioId != null)
                      _item(Icons.badge_outlined, 'Ver meu perfil público',
                          () => _abrir(PerfilPublicoDoadorScreen(
                              usuarioId: _usuarioId!))),
                    _item(Icons.volunteer_activism_outlined, 'Minhas doações',
                        () => _abrir(const MinhasDoacoesScreen())),
                    _item(Icons.favorite_outline, 'Favoritos',
                        () => _abrir(const FavoritosScreen())),
                    _item(Icons.emoji_events_outlined, 'Conquistas',
                        () => _abrir(const ConquistasScreen())),
                    _item(Icons.notifications_outlined, 'Notificações',
                        () => _abrir(const NotificacoesScreen())),
                    _item(Icons.settings_outlined, 'Configurações',
                        () => _abrir(const ConfiguracoesScreen())),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  _secao('Sobre o projeto', [
                    _item(Icons.info_outline_rounded, 'Sobre o Connect ONG',
                        () => _abrir(const DescricaoScreen())),
                    _item(Icons.code_rounded, 'Sobre o Desenvolvimento',
                        () => _abrir(const DesenvolvimentoChatScreen())),
                    _item(Icons.groups_rounded, 'Integrantes do projeto',
                        () => _abrir(const IntegrantesProjetoScreen())),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.brLg),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---- Cabecalho: avatar + nome + email ----
  Widget _cabecalho() {
    final cs = Theme.of(context).colorScheme;
    final iniciais = _nome.isNotEmpty ? _nome[0].toUpperCase() : '?';
    final avatarImg = _avatarImagem();

    return Row(
      children: [
        Hero(
          tag: 'avatar-doador',
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary,
            backgroundImage: avatarImg,
            child: avatarImg == null
                ? Text(iniciais,
                    style: const TextStyle(
                        fontSize: 30, color: AppColors.onPrimary))
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nome.isEmpty ? 'Doador(a)' : _nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface),
              ),
              Text(
                _email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              // Nota média que as ONGs deram a este doador (quando existe).
              if (_totalAvaliacoes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      for (int i = 0; i < 5; i++)
                        Icon(
                          i < _notaMedia.round().clamp(0, 5)
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: AppColors.ouro,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '${_notaMedia.toStringAsFixed(1)} ($_totalAvaliacoes)',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Editar perfil',
          onPressed: () => _abrir(const EditarPerfilScreen()),
          icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
        ),
      ],
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

  // ---- Menu em secoes (lista de itens dentro de um card) ----
  Widget _secao(String titulo, List<Widget> itens) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            titulo,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(children: itens),
        ),
      ],
    );
  }

  Widget _item(IconData icone, String rotulo, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icone, color: AppColors.primary),
      title: Text(rotulo,
          style: TextStyle(color: cs.onSurface, fontSize: 15)),
      trailing:
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
      onTap: onTap,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
    );
  }
}
