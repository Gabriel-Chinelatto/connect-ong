import 'package:flutter/material.dart';

import '../config/config_controller.dart';
import '../data/versoes.dart';
import '../pages/login_page.dart';
import '../screens/legal/documentos_legais_screen.dart';
import '../services/estatistica_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/page_transition.dart';

/// Portal institucional publico (face web do Connect ONG).
/// Apresenta missao, estatisticas publicas (transparencia), ODS, como
/// funciona, equipe, FAQ e os documentos legais (LGPD).
///
/// CHAMADAS PARA AÇÃO (revisão 2026-08): existe UM caminho de login (o botão
/// "Entrar" do topo). O herói traz a ação de valor ("Quero doar") e um atalho
/// que ROLA até "Como funciona" — antes eram três botões colados fazendo a
/// mesma coisa, o que confundia quem chegava.
class PortalInstitucionalScreen extends StatefulWidget {
  const PortalInstitucionalScreen({super.key});

  @override
  State<PortalInstitucionalScreen> createState() =>
      _PortalInstitucionalScreenState();
}

class _PortalInstitucionalScreenState extends State<PortalInstitucionalScreen> {
  // Já começa com o último valor conhecido (cache do serviço): voltar ao
  // portal não pisca mais "0" enquanto a API responde.
  EstatisticasPublicas _stats =
      EstatisticaService.cacheAtual ?? EstatisticasPublicas.zero;
  bool _statsCarregadas = EstatisticaService.cacheAtual != null;

  /// Quantas versões mostrar de início na seção "Versões" (as demais entram
  /// no "Ver todas as versões").
  static const int _versoesIniciais = 5;
  bool _mostrarTodasVersoes = false;

  /// Âncoras das seções (o herói e o topo rolam até elas).
  final GlobalKey _kComoFunciona = GlobalKey();
  final GlobalKey _kEquipe = GlobalKey();
  final GlobalKey _kVersoes = GlobalKey();

  /// Tema CLARO fixo do portal, criado uma vez (montar um ThemeData a cada
  /// rebuild custa caro por causa da fonte).
  ThemeData? _temaPortal;
  List<bool>? _configTema;

  @override
  void initState() {
    super.initState();
    EstatisticaService().carregar().then((s) {
      if (mounted) {
        setState(() {
          _stats = s;
          _statsCarregadas = true;
        });
      }
    }).catchError((_) {/* mantem os traços se a API estiver fora */});
  }

  void _entrar() {
    Navigator.push(context, PageTransition.fade(const LoginPage()));
  }

  void _abrirDoc(DocumentoLegal tipo) {
    Navigator.push(
        context, PageTransition.fade(DocumentosLegaisScreen(tipo: tipo)));
  }

  void _rolarAte(GlobalKey chave) {
    final ctx = chave.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  /// O portal é a vitrine pública: fica SEMPRE claro, mesmo com o app no tema
  /// escuro. Envolver a árvore num tema claro (em vez de só pintar os fundos)
  /// garante que nenhum texto herde o branco do tema escuro e suma.
  ThemeData _tema() {
    final c = ConfigController.instance;
    final atual = [c.fonteDislexia, c.altoContraste, c.navegacaoSimplificada];
    if (_temaPortal == null ||
        _configTema == null ||
        _configTema![0] != atual[0] ||
        _configTema![1] != atual[1] ||
        _configTema![2] != atual[2]) {
      _configTema = atual;
      _temaPortal = AppTheme.light(
        dislexia: c.fonteDislexia,
        altoContraste: c.altoContraste,
        navegacaoSimplificada: c.navegacaoSimplificada,
      );
    }
    return _temaPortal!;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _tema(),
      child: Scaffold(
        // Portal público sempre claro, nas cores do design system.
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _AppBarTopo(
                onEntrar: _entrar,
                onComoFunciona: () => _rolarAte(_kComoFunciona),
                onEquipe: () => _rolarAte(_kEquipe),
                onVersoes: () => _rolarAte(_kVersoes),
              ),
              _hero(),
              _faixaEstatisticas(),
              _secaoSobre(),
              _secaoComoFunciona(),
              _secaoOds(),
              _secaoEquipe(),
              _secaoFaq(),
              _secaoTransparencia(),
              _secaoVersoes(),
              _rodape(),
            ],
          ),
        ),
      ),
    );
  }

  // Limita a largura do conteudo e centraliza (responsivo).
  Widget _conteudo(
      {required Widget child, Color? cor, EdgeInsets? padding, Key? chave}) {
    return Container(
      key: chave,
      width: double.infinity,
      color: cor,
      padding: padding ??
          const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: child,
        ),
      ),
    );
  }

  Widget _tituloSecao(String titulo, String subtitulo) {
    return Column(
      children: [
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),
      ],
    );
  }

  // ---------------------------------------------------------------- HERO
  Widget _hero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.brXl,
                ),
                child: const Icon(Icons.volunteer_activism,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 28),
              Text(
                'Conectando quem quer ajudar\na quem precisa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'O Connect ONG aproxima doadores e organizações sociais, '
                'tornando as doações simples, transparentes e cheias de propósito.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 34),
              // UMA ação principal (leva ao login/cadastro) + UM atalho que
              // apenas rola a página. O login "puro" fica só no topo.
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _Elevavel(
                    child: ElevatedButton.icon(
                      onPressed: _entrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 18),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.brMd),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('Quero doar'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _rolarAte(_kComoFunciona),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 18),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    label: const Text('Como funciona'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'É gratuito para doadores e para ONGs. Criar a conta leva menos '
                'de um minuto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------- ESTATISTICAS (live)
  Widget _faixaEstatisticas() {
    // Enquanto a API não responde, mostra "—" em vez de zeros: o backend
    // gratuito hiberna e podia levar até um minuto exibindo "0 ONGs".
    String n(int v) => _statsCarregadas ? v.toString() : '—';
    final itens = <List<dynamic>>[
      [Icons.diversity_3, n(_stats.totalOngs), 'ONGs cadastradas'],
      [Icons.people_alt, n(_stats.totalDoadores), 'Doadores'],
      [Icons.campaign, n(_stats.totalNecessidades), 'Necessidades'],
      [Icons.handshake, n(_stats.totalMatches), 'Conexões (matches)'],
      [
        Icons.attach_money,
        // Mesma formatação de dinheiro do resto do app (R$ 1.234,50).
        _statsCarregadas ? formatarReais(_stats.valorTotalDoado) : '—',
        'Doado via PIX'
      ],
      [Icons.fact_check, n(_stats.totalPrestacoes), 'Prestações de contas'],
    ];

    return _conteudo(
      cor: Colors.white,
      child: Column(
        children: [
          _tituloSecao(
              'Transparência em números',
              _statsCarregadas
                  ? 'Dados públicos da plataforma, atualizados em tempo real.'
                  // O servidor gratuito hiberna: a 1ª visita pode levar até um
                  // minuto. Dizer isso é melhor do que a pessoa achar que os
                  // números não existem.
                  : 'Buscando os dados no servidor… se ele estava em repouso, '
                      'isso pode levar alguns segundos.'),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: itens
                .map((e) => _cardEstatistica(
                    e[0] as IconData, e[1] as String, e[2] as String))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _cardEstatistica(IconData icone, String numero, String rotulo) {
    return _Elevavel(
      subida: 5,
      child: Container(
        // 300px: com a largura máxima de 1100 cabem exatamente 3 por linha,
        // então os 6 números fecham 3+3. Com 240 dava 4+2 e a faixa ficava
        // visivelmente torta.
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icone, color: AppColors.primary, size: 34),
            const SizedBox(height: 12),
            // Os números entram animados quando a API responde (de 0 até o
            // valor), em vez de "pularem" na tela.
            _NumeroAnimado(
              texto: numero,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              rotulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------- SOBRE
  Widget _secaoSobre() {
    return _conteudo(
      child: Column(
        children: [
          _tituloSecao('O que é o Connect ONG',
              'Uma ponte digital entre a generosidade e quem mais precisa.'),
          Wrap(
            spacing: 22,
            runSpacing: 22,
            alignment: WrapAlignment.center,
            children: const [
              _CardValor(
                icone: Icons.flag,
                titulo: 'Missão',
                texto:
                    'Facilitar e dar transparência às doações, conectando '
                    'doadores a ONGs de forma simples e confiável.',
              ),
              _CardValor(
                icone: Icons.visibility,
                titulo: 'Visão',
                texto:
                    'Ser a principal plataforma de doações solidárias, '
                    'reconhecida pela transparência e pelo impacto social.',
              ),
              _CardValor(
                icone: Icons.favorite,
                titulo: 'Valores',
                texto:
                    'Solidariedade, transparência, respeito às pessoas e '
                    'compromisso com o impacto real na comunidade.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------- COMO FUNCIONA
  Widget _secaoComoFunciona() {
    return _conteudo(
      chave: _kComoFunciona,
      cor: Colors.white,
      child: Column(
        children: [
          _tituloSecao(
              'Como funciona', 'Da necessidade à doação, em poucos passos.'),
          Wrap(
            spacing: 22,
            runSpacing: 22,
            alignment: WrapAlignment.center,
            children: const [
              _CardPasso(
                  numero: '1',
                  titulo: 'A ONG publica',
                  texto:
                      'Organizações cadastram suas necessidades e campanhas.'),
              _CardPasso(
                  numero: '2',
                  titulo: 'O doador encontra',
                  texto:
                      'Busque ONGs e necessidades por causa, cidade ou urgência.'),
              _CardPasso(
                  numero: '3',
                  titulo: 'A conexão acontece',
                  texto:
                      'Doe itens ou via PIX, converse no chat e acompanhe a '
                      'prestação de contas.'),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- ODS
  Widget _secaoOds() {
    return _conteudo(
      child: Column(
        children: [
          _tituloSecao('Alinhado aos ODS da ONU',
              'O projeto contribui para os Objetivos de Desenvolvimento Sustentável.'),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: const [
              _CardOds(
                  numero: '1',
                  cor: Color(0xFFE5243B),
                  titulo: 'Erradicação da Pobreza'),
              _CardOds(
                  numero: '2', cor: Color(0xFFDDA63A), titulo: 'Fome Zero'),
              _CardOds(
                  numero: '10',
                  cor: Color(0xFFDD1367),
                  titulo: 'Redução das Desigualdades'),
              _CardOds(
                  numero: '17',
                  cor: Color(0xFF19486A),
                  titulo: 'Parcerias pelos Objetivos'),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ EQUIPE
  Widget _secaoEquipe() {
    const equipe = [
      ['Gabriel Chinelatto', 'Back-end e Designer', 'assets/images/gabriel.jpg'],
      ['Arthur Souza', 'Designer e Tester', 'assets/images/arthur.jpg'],
      ['Luan Felipe', 'Back-end e Designer', 'assets/images/luan.png'],
      ['Abner Viola', 'Front-end', 'assets/images/abner.jpg'],
    ];
    return _conteudo(
      chave: _kEquipe,
      cor: Colors.white,
      child: Column(
        children: [
          _tituloSecao('Quem faz acontecer',
              'Estudantes do 4º DSN do COTIL/UNICAMP por trás do projeto.'),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: equipe
                .map((e) => _cardIntegrante(e[0], e[1], e[2]))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _cardIntegrante(String nome, String papel, String foto) {
    return _Elevavel(
      subida: 5,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.brLg,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.asset(
                foto,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                // Cache no tamanho exibido: evita decodificar a foto inteira
                // (as imagens da equipe são grandes) e deixa a página leve.
                cacheWidth: 270,
                errorBuilder: (_, _, _) => const CircleAvatar(
                  radius: 45,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              nome,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              papel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- FAQ
  Widget _secaoFaq() {
    final faq = <List<String>>[
      [
        'O Connect ONG cobra alguma taxa?',
        'Não. A plataforma é gratuita para doadores e ONGs. Não cobramos taxa '
            'sobre as doações.'
      ],
      [
        'Como sei que a ONG é confiável?',
        'ONGs podem receber um selo de verificação, e você acompanha avaliações '
            'e prestações de contas de outras doações.'
      ],
      [
        'Que tipo de doação posso fazer?',
        'Itens (roupas, alimentos, materiais) atendendo necessidades publicadas, '
            'ou doações financeiras via PIX.'
      ],
      [
        'Meus dados estão protegidos?',
        'Sim. Seguimos a LGPD: você controla suas informações e consente com o '
            'uso delas. Veja nossa Política de Privacidade.'
      ],
    ];
    return _conteudo(
      child: Column(
        children: [
          _tituloSecao('Perguntas frequentes', 'Tire suas principais dúvidas.'),
          ...faq.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.brLg,
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(22, 0, 22, 18),
                      iconColor: AppColors.primary,
                      title: Text(
                        e[0],
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            e[1],
                            style: TextStyle(
                                color: AppColors.textSecondary, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ----------------------------------------------------- TRANSPARENCIA
  Widget _secaoTransparencia() {
    return _conteudo(
      cor: Colors.white,
      child: Column(
        children: [
          _tituloSecao('Transparência e privacidade',
              'Compromisso com a clareza e com a proteção dos seus dados (LGPD).'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _abrirDoc(DocumentoLegal.privacidade),
                style: _botaoDoc(),
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text('Política de Privacidade'),
              ),
              OutlinedButton.icon(
                onPressed: () => _abrirDoc(DocumentoLegal.termos),
                style: _botaoDoc(),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Termos de Uso'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ButtonStyle _botaoDoc() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        textStyle:
            TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );

  // --------------------------------------------------------- VERSOES
  Widget _secaoVersoes() {
    final total = kVersoesApp.length;
    final visiveis = _mostrarTodasVersoes
        ? kVersoesApp
        : kVersoesApp.take(_versoesIniciais).toList();
    return _conteudo(
      chave: _kVersoes,
      child: Column(
        children: [
          _tituloSecao(
              'Versões', 'A evolução do Connect ONG, versão a versão.'),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  ...visiveis.map(_cardVersao),
                  if (total > _versoesIniciais) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(
                          () => _mostrarTodasVersoes = !_mostrarTodasVersoes),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        textStyle: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      icon: Icon(_mostrarTodasVersoes
                          ? Icons.expand_less
                          : Icons.expand_more),
                      label: Text(_mostrarTodasVersoes
                          ? 'Ver menos'
                          : 'Ver todas as versões'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardVersao(VersaoApp v) {
    final atual = v.atual;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: atual
                ? AppColors.primary.withValues(alpha: 0.55)
                : AppColors.border,
            width: atual ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: atual,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textSecondary,
            leading: Container(
              width: 56,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_offer,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    v.numero,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    v.titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (atual)
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.brXl,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.rocket_launch,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Atual',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            children: [
              for (final m in v.mudancas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 7, right: 10),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          m,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ RODAPE
  Widget _rodape() {
    return Container(
      width: double.infinity,
      // Rodapé escuro no tom de texto da marca (design system).
      color: AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volunteer_activism,
                      color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Connect ONG',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Projeto Integrador • COTIL / UNICAMP • 2026',
                style: TextStyle(
                    color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Feito com 💚 para causar impacto social.',
                style: TextStyle(
                    color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ COMPONENTES

/// Número da faixa de transparência: troca com um fade + leve subida quando a
/// API responde (antes o valor pulava de 0 para o real, sem transição).
class _NumeroAnimado extends StatelessWidget {
  final String texto;
  final TextStyle style;
  const _NumeroAnimado({required this.texto, required this.style});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      transitionBuilder: (filho, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: filho,
        ),
      ),
      child: Text(texto, key: ValueKey(texto), style: style),
    );
  }
}

/// Faz um card REAGIR ao mouse: sobe alguns pixels e ganha uma sombra verde.
/// Cada card é um StatefulWidget próprio, então o hover só reconstrói ele —
/// a página inteira não repinta (isso é o que mantém a rolagem leve).
class _Elevavel extends StatefulWidget {
  final Widget child;

  /// Quantos pixels o card sobe no hover.
  final double subida;

  const _Elevavel({required this.child, this.subida = 6});

  @override
  State<_Elevavel> createState() => _ElevavelState();
}

class _ElevavelState extends State<_Elevavel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -widget.subida : 0, 0),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: _hover ? 0.22 : 0.0),
              blurRadius: _hover ? 24 : 0,
              offset: Offset(0, _hover ? 12 : 0),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Barra do topo: marca à esquerda, atalhos de navegação (só em telas largas)
/// e o ÚNICO botão de login do portal.
class _AppBarTopo extends StatelessWidget {
  final VoidCallback onEntrar;
  final VoidCallback onComoFunciona;
  final VoidCallback onEquipe;
  final VoidCallback onVersoes;

  const _AppBarTopo({
    required this.onEntrar,
    required this.onComoFunciona,
    required this.onEquipe,
    required this.onVersoes,
  });

  @override
  Widget build(BuildContext context) {
    // Em telas estreitas (celular) só cabem marca + Entrar.
    final bool largo = MediaQuery.of(context).size.width >= 860;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.volunteer_activism,
                      color: AppColors.primary, size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Connect ONG',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  if (largo) ...[
                    _LinkTopo(texto: 'Como funciona', onTap: onComoFunciona),
                    _LinkTopo(texto: 'Equipe', onTap: onEquipe),
                    _LinkTopo(texto: 'Versões', onTap: onVersoes),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  ElevatedButton.icon(
                    onPressed: onEntrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.brMd),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Entrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Link de navegação do topo, com sublinhado que cresce no hover.
class _LinkTopo extends StatefulWidget {
  final String texto;
  final VoidCallback onTap;
  const _LinkTopo({required this.texto, required this.onTap});

  @override
  State<_LinkTopo> createState() => _LinkTopoState();
}

class _LinkTopoState extends State<_LinkTopo> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _hover ? AppColors.primary : AppColors.textSecondary,
                ),
                child: Text(widget.texto),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 2,
                width: _hover ? 22 : 0,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardValor extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String texto;
  const _CardValor(
      {required this.icone, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return _Elevavel(
      child: Container(
        width: 320,
        // Altura mínima igual nos três: sem isto o card do meio ficava mais
        // alto que os vizinhos (o texto é maior) e a linha ficava desalinhada.
        constraints: const BoxConstraints(minHeight: 230),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.brLg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(icone, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPasso extends StatelessWidget {
  final String numero;
  final String titulo;
  final String texto;
  const _CardPasso(
      {required this.numero, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return _Elevavel(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(26),
        decoration: const BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.brLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: Text(
                numero,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              style: const TextStyle(
                  color: AppColors.textSecondary, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardOds extends StatelessWidget {
  final String numero;
  final Color cor;
  final String titulo;
  const _CardOds(
      {required this.numero, required this.cor, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return _Elevavel(
      subida: 8,
      child: Container(
        width: 230,
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: AppRadius.brLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ODS $numero',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
