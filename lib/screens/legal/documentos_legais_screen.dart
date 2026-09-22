import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Documentos legais da plataforma (LGPD — Lei 13.709/2018).
///
/// Uma única tela que exibe a Política de Privacidade ou os Termos de Uso,
/// de acordo com o [tipo] informado. Usada na Central de Configurações, no
/// fluxo de cadastro (consentimento) e no portal institucional.
///
/// FORMATO (redesenho 2026-08): segue o padrão dos documentos legais dos apps
/// grandes — capa com a data de atualização, um "Em resumo" em linguagem
/// simples, um sumário que salta para a seção e o texto em seções numeradas.
/// Todo o conteúdo é selecionável (copiar/colar) e respeita o tema claro/escuro.
enum DocumentoLegal { privacidade, termos }

class DocumentosLegaisScreen extends StatefulWidget {
  final DocumentoLegal tipo;

  const DocumentosLegaisScreen({super.key, required this.tipo});

  @override
  State<DocumentosLegaisScreen> createState() => _DocumentosLegaisScreenState();
}

class _DocumentosLegaisScreenState extends State<DocumentosLegaisScreen> {
  /// Documento exibido (dá para alternar Política ↔ Termos pelo rodapé, sem
  /// empilhar telas).
  late DocumentoLegal _tipo = widget.tipo;

  final ScrollController _scroll = ScrollController();

  /// Âncoras das seções, para o sumário rolar até elas.
  final Map<int, GlobalKey> _ancoras = {};

  _DocumentoConteudo get _doc =>
      _tipo == DocumentoLegal.privacidade ? _politicaPrivacidade : _termosDeUso;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _irPara(int indice) {
    final ctx = _ancoras[indice]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _trocarDocumento() {
    setState(() {
      _tipo = _tipo == DocumentoLegal.privacidade
          ? DocumentoLegal.termos
          : DocumentoLegal.privacidade;
      _ancoras.clear();
    });
    // Volta ao topo ao trocar de documento.
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(doc.tituloCurto),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
      ),
      // Documento jurídico: o usuário precisa poder selecionar e copiar.
      body: SelectionArea(
        child: Center(
          child: ConstrainedBox(
            // Coluna de leitura confortável também na web/desktop.
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
              children: [
                _capa(doc),
                const SizedBox(height: AppSpacing.md),
                _emResumo(doc),
                const SizedBox(height: AppSpacing.md),
                _sumario(doc),
                const SizedBox(height: AppSpacing.lg),
                for (int i = 0; i < doc.secoes.length; i++) ...[
                  _secao(i, doc.secoes[i]),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.sm),
                _rodape(doc),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ CAPA
  Widget _capa(_DocumentoConteudo doc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(doc.icone, color: Colors.white, size: 26),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            doc.titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            doc.subtitulo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _selo(Icons.event_available_rounded,
                  'Atualizado em ${doc.atualizacao}'),
              _selo(Icons.schedule_rounded, 'Leitura de ${doc.minutos} min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selo(IconData icone, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- EM RESUMO
  Widget _emResumo(_DocumentoConteudo doc) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Em resumo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'O essencial em linguagem simples. O texto completo está abaixo e '
            'é o que vale juridicamente.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final r in doc.resumo)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      r,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- SUMÁRIO
  Widget _sumario(_DocumentoConteudo doc) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
                AppSpacing.md, AppSpacing.sm),
            child: Text(
              'Sumário',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          for (int i = 0; i < doc.secoes.length; i++)
            InkWell(
              onTap: () => _irPara(i),
              borderRadius: i == doc.secoes.length - 1
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.lg))
                  : BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 11),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        doc.secoes[i].titulo,
                        style: TextStyle(fontSize: 14, color: cs.onSurface),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- SEÇÕES
  Widget _secao(int indice, _SecaoLegal s) {
    final cs = Theme.of(context).colorScheme;
    final chave = _ancoras.putIfAbsent(indice, () => GlobalKey());
    return Container(
      key: chave,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brSm,
                ),
                child: Text(
                  '${indice + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    s.titulo,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            s.texto,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.62,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- RODAPÉ
  Widget _rodape(_DocumentoConteudo doc) {
    final cs = Theme.of(context).colorScheme;
    final outro = _tipo == DocumentoLegal.privacidade
        ? 'Ler os Termos de Uso'
        : 'Ler a Política de Privacidade';
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _trocarDocumento,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14.5),
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(outro),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Connect ONG • Última atualização: ${doc.atualizacao}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Em conformidade com a LGPD — Lei nº 13.709/2018.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// =========================================================================
// Conteudo dos documentos (compartilhado pela UI)
// =========================================================================

class _SecaoLegal {
  final String titulo;
  final String texto;
  const _SecaoLegal(this.titulo, this.texto);
}

class _DocumentoConteudo {
  final String titulo;

  /// Título curto para a AppBar (o longo quebraria a barra).
  final String tituloCurto;
  final String subtitulo;
  final IconData icone;
  final String atualizacao;

  /// Tempo estimado de leitura, em minutos (informado na capa).
  final int minutos;

  /// "Em resumo": o essencial em linguagem simples, antes do texto formal.
  final List<String> resumo;
  final List<_SecaoLegal> secoes;

  const _DocumentoConteudo({
    required this.titulo,
    required this.tituloCurto,
    required this.subtitulo,
    required this.icone,
    required this.atualizacao,
    required this.minutos,
    required this.resumo,
    required this.secoes,
  });
}

const _DocumentoConteudo _politicaPrivacidade = _DocumentoConteudo(
  titulo: 'Política de Privacidade',
  tituloCurto: 'Privacidade',
  subtitulo:
      'Como o Connect ONG coleta, usa e protege os seus dados pessoais.',
  icone: Icons.shield_outlined,
  // Versão 2026-09-22: a MESMA gravada no aceite (Consentimento.VERSAO_ATUAL
  // na API). Se o texto mudar, suba as duas.
  atualizacao: 'Setembro de 2026 (versão 2026-09-22)',
  minutos: 5,
  resumo: [
    'Coletamos só o necessário para conectar você a uma ONG.',
    'Seu telefone e suas conversas ficam criptografados no nosso banco.',
    'Não vendemos os seus dados para ninguém.',
    'Você vê e copia tudo o que guardamos em "Privacidade e meus dados".',
    'Ao excluir a conta, seus dados pessoais são anonimizados na hora.',
  ],
  secoes: [
    _SecaoLegal(
      'Quem somos',
      'O Connect ONG é uma plataforma que conecta doadores a organizações '
          'não governamentais (ONGs), facilitando doações de itens e '
          'financeiras. Esta política explica como tratamos seus dados '
          'pessoais, em conformidade com a Lei Geral de Proteção de Dados '
          '(LGPD — Lei nº 13.709/2018). O projeto é desenvolvido por '
          'estudantes do COTIL/UNICAMP; enquanto não houver uma pessoa '
          'jurídica operando a plataforma, a equipe do projeto responde '
          'como controladora e encarregada dos dados.',
    ),
    _SecaoLegal(
      'Dados que coletamos',
      'Conta: nome, e-mail e senha (guardada só como um resumo irreversível, '
          'BCrypt). Perfil, se você informar: telefone, cidade, estado, bio e '
          'foto. Uso: interesses em necessidades, mensagens do chat, doações, '
          'avaliações, favoritos e notificações. Segurança: registro de acessos '
          '(data e endereço IP). Consentimento: a versão dos Termos e desta '
          'Política que você aceitou, com data e IP.',
    ),
    _SecaoLegal(
      'Por que usamos (bases legais)',
      'Para executar o serviço que você pediu — criar a conta, conectar você '
          'à ONG, abrir o chat e registrar doações (LGPD, art. 7º, V). Com o '
          'seu consentimento — exibir telefone ou e-mail, perfil público e '
          'notificações opcionais (art. 7º, I), que você liga e desliga em '
          'Privacidade. Por legítimo interesse — prevenir fraudes e proteger '
          'sua conta com o registro de acessos (art. 7º, IX). Para cumprir a '
          'lei — o Marco Civil da Internet exige guardar registros de acesso '
          'por 6 meses (art. 7º, II).',
    ),
    _SecaoLegal(
      'Compartilhamento',
      'Seus dados de contato só aparecem para outras pessoas quando você '
          'autoriza em Privacidade. Ao demonstrar interesse em uma necessidade, '
          'a ONG recebe o necessário para concluir a doação. Usamos dois '
          'fornecedores fora do Brasil (art. 33): a hospedagem da API (Render, '
          'EUA) e o provedor de inteligência artificial (Groq, EUA). Antes de '
          'uma pergunta sua ir para a IA, removemos e-mail, telefone, CPF e '
          'CNPJ do texto. Não vendemos dados a ninguém.',
    ),
    _SecaoLegal(
      'Por quanto tempo guardamos',
      'Enquanto a sua conta existir. Ao excluir a conta, nome, e-mail, '
          'telefone, cidade, bio e foto são anonimizados na mesma hora; o que '
          'sobra (por exemplo, "uma doação de R\$ 50 foi feita") não '
          'identifica mais você e continua contando para a transparência da '
          'ONG (art. 16). Registros de acesso ficam 6 meses, como exige o '
          'Marco Civil da Internet.',
    ),
    _SecaoLegal(
      'Seus direitos (LGPD, art. 18)',
      'Confirmar e acessar seus dados e levá-los com você: Configurações › '
          'Privacidade e meus dados mostra tudo e copia em formato JSON. '
          'Corrigir: Editar perfil. Excluir: Configurações › Zona de perigo. '
          'Revogar um consentimento: desligue a opção em Privacidade. Para '
          'qualquer outro pedido, fale com a equipe do projeto.',
    ),
    _SecaoLegal(
      'Segurança',
      'Seu telefone, as mensagens do chat e as denúncias são guardados '
          'criptografados (AES-256-GCM): quem abrir o banco de dados vê só '
          'texto embaralhado. Senhas ficam em BCrypt e códigos de verificação '
          'em HMAC — nenhum dos dois pode ser lido de volta. A comunicação é '
          'por HTTPS, cada tela só mostra os dados do próprio dono e há limite '
          'de tentativas contra quem tenta adivinhar senhas. Nenhum sistema é '
          '100% imune: mantenha sua senha em sigilo e ative a verificação em '
          'duas etapas.',
    ),
    _SecaoLegal(
      'Alterações desta política',
      'Quando esta política mudar, a versão nova recebe outra data e você '
          'verá o aviso dentro do app. Em "Privacidade e meus dados" fica '
          'registrado qual versão você aceitou e quando.',
    ),
    _SecaoLegal(
      'Contato',
      'Dúvidas sobre esta política ou pedidos sobre os seus dados: fale com '
          'a equipe do Connect ONG pelos canais oficiais do projeto.',
    ),
  ],
);

const _DocumentoConteudo _termosDeUso = _DocumentoConteudo(
  titulo: 'Termos de Uso',
  tituloCurto: 'Termos de Uso',
  subtitulo:
      'As regras para usar o Connect ONG e o que esperamos de cada pessoa.',
  icone: Icons.gavel_rounded,
  atualizacao: 'Julho de 2026',
  minutos: 3,
  resumo: [
    'Usar a plataforma é gratuito, para doadores e para ONGs.',
    'Somos a ponte: a doação em si é um acordo entre você e a ONG.',
    'Informações verdadeiras e respeito são obrigatórios.',
    'Contas que desrespeitarem as regras podem ser suspensas.',
  ],
  secoes: [
    _SecaoLegal(
      'Aceitação',
      'Ao criar uma conta e utilizar o Connect ONG, você concorda com estes '
          'Termos de Uso e com a Política de Privacidade. Se você não '
          'concordar, não utilize a plataforma.',
    ),
    _SecaoLegal(
      'A plataforma',
      'O Connect ONG é uma ponte entre doadores e ONGs. Não somos parte das '
          'doações em si: facilitamos o encontro e a comunicação entre as '
          'partes. A responsabilidade pela entrega e pelo uso correto das '
          'doações é das partes envolvidas.',
    ),
    _SecaoLegal(
      'Responsabilidades do usuário',
      'Você se compromete a fornecer informações verdadeiras, manter a sua '
          'senha em sigilo, respeitar as outras pessoas e ONGs e não utilizar '
          'a plataforma para fins ilegais, fraudulentos ou que violem '
          'direitos de terceiros.',
    ),
    _SecaoLegal(
      'Conteúdo e conduta',
      'É proibido publicar conteúdo ofensivo, enganoso ou que desrespeite a '
          'dignidade de qualquer pessoa ou organização. Contas que '
          'descumprirem estas regras podem ser suspensas ou removidas.',
    ),
    _SecaoLegal(
      'Doações',
      'As doações registradas na plataforma são um compromisso entre doador e '
          'ONG. O Connect ONG não cobra taxas sobre doações e não se '
          'responsabiliza por acordos firmados fora da plataforma.',
    ),
    _SecaoLegal(
      'Alterações',
      'Podemos atualizar estes Termos para refletir melhorias ou exigências '
          'legais. Mudanças relevantes serão comunicadas dentro do app. O uso '
          'continuado após as mudanças representa concordância com a nova '
          'versão.',
    ),
  ],
);
