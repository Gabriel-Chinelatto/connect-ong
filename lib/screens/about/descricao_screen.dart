import 'package:flutter/material.dart';

import '../../data/versoes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_footer.dart';

/// Tela "Sobre o Projeto" do app do doador.
///
/// Apresenta o Connect ONG: descricao, funcionalidades, compromisso com
/// seguranca/LGPD/ODS, equipe, historico de VERSOES (changelog) e contexto
/// academico. Totalmente THEME-AWARE: usa as cores do ColorScheme, entao fica
/// legivel e coerente tanto no tema claro quanto no escuro (o verde da marca
/// segue como acento nos dois).
class DescricaoScreen extends StatefulWidget {
  const DescricaoScreen({super.key});

  @override
  State<DescricaoScreen> createState() => _DescricaoScreenState();
}

class _DescricaoScreenState extends State<DescricaoScreen> {
  static const int _versoesIniciais = 5;
  bool _mostrarTodasVersoes = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Sobre o Projeto',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          children: [
            Hero(
              tag: 'logo_app',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset('assets/images/logo.jpg',
                    width: 135, height: 135, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connect Ong',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Conectando solidariedade e tecnologia',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 34),

            _card(
              cs,
              title: 'O Projeto',
              icon: Icons.lightbulb_outline,
              child: Text(
                'O Connect Ong é uma plataforma desenvolvida para aproximar '
                'doadores e instituições sociais, promovendo a solidariedade '
                'através da tecnologia. O sistema permite cadastrar, gerenciar '
                'e localizar doações de forma simples, rápida e intuitiva.',
                textAlign: TextAlign.justify,
                style: TextStyle(
                    fontSize: 15, height: 1.7, color: cs.onSurface),
              ),
            ),
            const SizedBox(height: 22),

            _card(
              cs,
              title: 'Funcionalidades',
              icon: Icons.dashboard_outlined,
              child: Column(
                children: const [
                  'Cadastro de doações',
                  'Busca de receptores',
                  'Gerenciamento de ONGs',
                  'Sistema intuitivo e responsivo',
                  'Interface moderna e acessível',
                ].map((t) => _bullet(cs, t)).toList(),
              ),
            ),
            const SizedBox(height: 22),

            _card(
              cs,
              title: 'Compromisso com Segurança e Transparência',
              icon: Icons.verified_user_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'O Connect Ong foi desenvolvido com foco em '
                    'responsabilidade digital, transparência e impacto social.',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        fontSize: 15, height: 1.7, color: cs.onSurface),
                  ),
                  const SizedBox(height: 18),
                  _bullet(cs,
                      'Adequação aos princípios da LGPD (Lei nº 13.709/2018), '
                      'garantindo o tratamento responsável dos dados pessoais.'),
                  _bullet(cs,
                      'Alinhamento ao Marco Regulatório das Organizações da '
                      'Sociedade Civil (Lei nº 13.019/2014), promovendo '
                      'transparência e fortalecimento das parcerias sociais.'),
                  _bullet(cs,
                      'Contribuição para o ODS 10 da ONU, auxiliando na '
                      'redução das desigualdades por meio da conexão entre '
                      'doadores e instituições.'),
                  _bullet(cs,
                      'Contribuição para o ODS 17 da ONU, incentivando '
                      'parcerias eficazes entre sociedade civil e tecnologia.'),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _card(
              cs,
              title: 'Equipe de Desenvolvimento',
              icon: Icons.groups_outlined,
              child: Column(
                children: const [
                  ['Gabriel Chinelatto', 'Back-end & Designer'],
                  ['Abner Viola', 'Front-end Developer'],
                  ['Luan Felipe', 'Back-end Developer'],
                  ['Arthur Souza', 'Designer & Tester'],
                ].map((m) => _membro(cs, m[0], m[1])).toList(),
              ),
            ),
            const SizedBox(height: 22),

            // ---- VERSOES (changelog) ----
            _card(
              cs,
              title: 'Versões',
              icon: Icons.history,
              child: _secaoVersoes(cs),
            ),
            const SizedBox(height: 30),

            // Cartao "Projeto Integrador".
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school_outlined,
                      size: 34, color: AppColors.primary),
                  const SizedBox(height: 14),
                  Text('Projeto Integrador',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    'Desenvolvido por alunos do 4°DSN - COTIL',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  const Text('2026',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const AppFooter(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ---- Seção de versões: 5 + "Ver todas", cada uma expansível ----
  Widget _secaoVersoes(ColorScheme cs) {
    final visiveis = _mostrarTodasVersoes
        ? kVersoesApp
        : kVersoesApp.take(_versoesIniciais).toList();
    final restantes = kVersoesApp.length - _versoesIniciais;
    return Column(
      children: [
        ...visiveis.map((v) => _cardVersao(cs, v)),
        if (!_mostrarTodasVersoes && restantes > 0)
          TextButton.icon(
            onPressed: () => setState(() => _mostrarTodasVersoes = true),
            icon: const Icon(Icons.expand_more),
            label: Text('Ver todas as versões ($restantes anteriores)'),
          ),
        if (_mostrarTodasVersoes)
          TextButton.icon(
            onPressed: () => setState(() => _mostrarTodasVersoes = false),
            icon: const Icon(Icons.expand_less),
            label: const Text('Ver menos'),
          ),
      ],
    );
  }

  Widget _cardVersao(ColorScheme cs, VersaoApp v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: v.atual ? AppColors.primary : cs.outlineVariant,
            width: v.atual ? 1.4 : 1),
      ),
      child: Theme(
        // Remove as linhas divisórias padrão do ExpansionTile.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: v.atual,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(v.numero,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
          title: Text(v.titulo,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: cs.onSurface)),
          subtitle: Text('Versão ${v.numero.replaceFirst('v', '')}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          trailing: v.atual
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Atual',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                )
              : null,
          children: v.mudancas
              .map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 10),
                          child: Icon(Icons.check_circle,
                              size: 16, color: AppColors.primary),
                        ),
                        Expanded(
                          child: Text(m,
                              style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: cs.onSurface)),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ---- Componentes de cartão/lista (theme-aware) ----
  Widget _card(ColorScheme cs,
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  static Widget _bullet(ColorScheme cs, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style:
                    TextStyle(fontSize: 15, height: 1.5, color: cs.onSurface)),
          ),
        ],
      ),
    );
  }

  static Widget _membro(ColorScheme cs, String nome, String cargo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(cargo,
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
