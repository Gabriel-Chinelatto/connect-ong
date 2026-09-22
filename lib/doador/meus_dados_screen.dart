import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/perfil_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/feedback/app_snackbar.dart';

/// "Privacidade e meus dados" — direitos do titular pela LGPD (item F-04 do
/// Plano de Ação; o avaliador da FECITEC apontou "não tem ... LGPD").
///
/// Mostra, com dados REAIS da API (`GET /usuarios/{id}/meus-dados`):
///  - o que a plataforma guarda sobre a pessoa e por quê (base legal);
///  - quando ela aceitou os Termos e a Política (e qual versão);
///  - um botão para copiar TUDO em JSON (portabilidade, art. 18, V).
/// A exclusão com anonimização continua na "Zona de perigo" das configurações.
class MeusDadosScreen extends StatefulWidget {
  final int usuarioId;

  const MeusDadosScreen({super.key, required this.usuarioId});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  Map<String, dynamic>? _dados;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final d = await PerfilService().meusDados(widget.usuarioId);
      if (mounted) setState(() => _dados = d);
    } catch (e) {
      if (mounted) {
        setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _copiar() async {
    final json = const JsonEncoder.withIndent('  ').convert(_dados);
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      AppSnackbar.sucesso(
        context,
        'Seus dados foram copiados em formato JSON.',
      );
    }
  }

  int _qtd(String chave) => (_dados?[chave] as List?)?.length ?? 0;

  String _data(dynamic iso) {
    if (iso == null) return '—';
    final s = iso.toString();
    if (s.length < 10) return s;
    return '${s.substring(8, 10)}/${s.substring(5, 7)}/${s.substring(0, 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e meus dados')),
      body:
          _erro != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _carregar,
                        child: const Text('Tentar de novo'),
                      ),
                    ],
                  ),
                ),
              )
              : _dados == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _cartao(
                    cs,
                    icone: Icons.verified_user_outlined,
                    titulo: 'Seus direitos (LGPD, art. 18)',
                    filhos: const [
                      _Direito(
                        'Acessar e levar seus dados',
                        'Veja abaixo e copie tudo em JSON.',
                      ),
                      _Direito(
                        'Corrigir',
                        'Edite nome, telefone, cidade e bio em "Editar perfil".',
                      ),
                      _Direito(
                        'Excluir',
                        'Em Configurações › Zona de perigo. Seus dados pessoais são anonimizados.',
                      ),
                      _Direito(
                        'Revogar permissões',
                        'Telefone, e-mail e perfil público se ligam e desligam em Privacidade.',
                      ),
                    ],
                  ),
                  _cartao(
                    cs,
                    icone: Icons.inventory_2_outlined,
                    titulo: 'O que guardamos sobre você',
                    filhos: [
                      _linha(
                        'Conta',
                        '${_dados!['conta']?['nome'] ?? ''} · ${_dados!['conta']?['email'] ?? ''}',
                      ),
                      _linha(
                        'Telefone',
                        (_dados!['conta']?['telefone'] ?? 'não informado')
                            .toString(),
                      ),
                      _linha(
                        'Interesses e conversas',
                        '${_qtd('interessesEConversas')}',
                      ),
                      _linha('Doações por PIX', '${_qtd('doacoesPix')}'),
                      _linha('Favoritos', '${_qtd('favoritos')}'),
                      _linha('Notificações', '${_qtd('notificacoes')}'),
                      _linha(
                        'Registros de acesso',
                        '${_qtd('registroDeAcessos')}',
                      ),
                    ],
                  ),
                  _cartao(
                    cs,
                    icone: Icons.lock_outline,
                    titulo: 'Como protegemos',
                    filhos: const [
                      _Direito(
                        'Criptografia',
                        'Seu telefone e suas conversas ficam cifrados no banco (AES-256).',
                      ),
                      _Direito(
                        'Senha',
                        'Guardamos só um resumo irreversível (BCrypt); ninguém consegue lê-la.',
                      ),
                      _Direito(
                        'IA',
                        'Antes de uma pergunta ir para a IA, removemos e-mail, telefone, CPF e CNPJ.',
                      ),
                    ],
                  ),
                  _cartao(
                    cs,
                    icone: Icons.fact_check_outlined,
                    titulo: 'Seu consentimento',
                    filhos: [
                      for (final c
                          in (_dados!['consentimentos'] as List? ?? const []))
                        _linha(
                          'Termos de Uso e Política de Privacidade',
                          'aceitos em ${_data(c['aceitoEm'])} (versão ${c['versao']})',
                        ),
                      if ((_dados!['consentimentos'] as List? ?? const [])
                          .isEmpty)
                        _linha(
                          'Termos de Uso e Política de Privacidade',
                          'conta criada antes do registro de aceite',
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: _copiar,
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copiar meus dados (JSON)'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
    );
  }

  Widget _cartao(
    ColorScheme cs, {
    required IconData icone,
    required String titulo,
    required List<Widget> filhos,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...filhos,
          ],
        ),
      ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              rotulo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(flex: 6, child: Text(valor)),
        ],
      ),
    );
  }
}

class _Direito extends StatelessWidget {
  final String titulo;
  final String texto;

  const _Direito(this.titulo, this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$titulo: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: texto),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
