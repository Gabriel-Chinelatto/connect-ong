import 'package:flutter/material.dart';

import '../models/conquista.dart';
import '../services/conquista_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/escala.dart';
import '../widgets/feedback/empty_state.dart';

/// Exibe as conquistas (gamificacao) desbloqueadas pelo doador conforme suas
/// acoes na plataforma. Exige sessao ativa para carregar as conquistas do usuario.
///
/// Redesenho (Bloco 21 / Fase 4): design system + tema (dark mode ok).
class ConquistasScreen extends StatefulWidget {
  const ConquistasScreen({super.key});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen> {
  final ConquistaService _service = ConquistaService();
  List<Conquista> _conquistas = [];
  bool _carregando = true;
  bool _semSessao = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _semSessao = false;
    });
    final usuario = await SessionService().obterUsuario();
    if (!mounted) return;
    final usuarioId = usuario?.id;
    if (usuarioId == null) {
      setState(() {
        _semSessao = true;
        _carregando = false;
      });
      return;
    }
    try {
      final lista = await _service.doador(usuarioId);
      if (!mounted) return;
      setState(() {
        _conquistas = lista;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  IconData _iconePara(String chave) {
    switch (chave) {
      case 'PRIMEIRA_DOACAO':
        return Icons.volunteer_activism;
      case 'DOADOR_RECORRENTE':
        return Icons.repeat;
      case 'CINCO_DOACOES':
        return Icons.filter_5;
      case 'DEZ_DOACOES':
        return Icons.military_tech;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _conquistas.length;
    final desbloqueadas = _conquistas.where((c) => c.conquistada).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conquistas'),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _semSessao
              ? _vazio(
                  icone: Icons.lock_outline,
                  mensagem: 'Faça login para ver suas conquistas',
                )
              : _conquistas.isEmpty
                  ? _vazio(
                      icone: Icons.emoji_events_outlined,
                      mensagem: 'Nenhuma conquista disponível',
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      color: AppColors.primary,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          _contador(desbloqueadas, total),
                          const SizedBox(height: AppSpacing.md),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _conquistas.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              // Cards mais altos quando a fonte aumenta.
                              childAspectRatio: 0.85 / fatorFonte(context),
                            ),
                            itemBuilder: (_, i) => _card(_conquistas[i]),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _contador(int desbloqueadas, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.brLg,
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.primary, size: 28),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$desbloqueadas de $total conquistadas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Conquista c) {
    final cs = Theme.of(context).colorScheme;
    final conquistada = c.conquistada;
    final corIcone = conquistada ? AppColors.primary : cs.onSurfaceVariant;
    final corFundoIcone = conquistada
        ? AppColors.primary.withValues(alpha: 0.12)
        : cs.surfaceContainerHighest;
    final corTitulo = conquistada ? cs.onSurface : cs.onSurfaceVariant;
    final corDescricao = cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: corFundoIcone,
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconePara(c.chave), color: corIcone, size: 32),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    conquistada ? Icons.check_circle : Icons.lock_outline,
                    size: 18,
                    color: conquistada ? AppColors.primary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            c.titulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: corTitulo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            c.descricao,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: corDescricao,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vazio({required IconData icone, required String mensagem}) {
    return EmptyState(icone: icone, mensagem: mensagem);
  }
}
