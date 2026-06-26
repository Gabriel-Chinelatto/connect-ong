import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/login_page.dart';
import '../screens/legal/documentos_legais_screen.dart';
import '../services/estatistica_service.dart';
import '../theme/app_colors.dart';

/// Portal institucional publico (face web do Connect ONG).
/// Apresenta missao, estatisticas publicas (transparencia), ODS, como
/// funciona, equipe, FAQ e os documentos legais (LGPD).
class PortalInstitucionalScreen extends StatefulWidget {
  const PortalInstitucionalScreen({super.key});

  @override
  State<PortalInstitucionalScreen> createState() =>
      _PortalInstitucionalScreenState();
}

class _PortalInstitucionalScreenState extends State<PortalInstitucionalScreen> {
  EstatisticasPublicas _stats = EstatisticasPublicas.zero;

  @override
  void initState() {
    super.initState();
    EstatisticaService().carregar().then((s) {
      if (mounted) setState(() => _stats = s);
    }).catchError((_) {/* mantem zeros se a API estiver fora */});
  }

  void _entrar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _abrirDoc(DocumentoLegal tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentosLegaisScreen(tipo: tipo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _AppBarTopo(onEntrar: _entrar),
            _hero(),
            _faixaEstatisticas(),
            _secaoSobre(),
            _secaoComoFunciona(),
            _secaoOds(),
            _secaoEquipe(),
            _secaoFaq(),
            _secaoTransparencia(),
            _rodape(),
          ],
        ),
      ),
    );
  }

  // Limita a largura do conteudo e centraliza (responsivo).
  Widget _conteudo({required Widget child, Color? cor, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      color: cor,
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
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
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B2B22),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitulo,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black54,
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
          colors: [AppColors.primary, Color(0xFF066537)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.volunteer_activism,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 28),
              Text(
                'Conectando quem quer ajudar\na quem precisa',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 34),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _entrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Entrar no app'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _entrar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    icon: const Icon(Icons.favorite_outline),
                    label: const Text('Quero doar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------- ESTATISTICAS (live)
  Widget _faixaEstatisticas() {
    final itens = <List<dynamic>>[
      [Icons.diversity_3, _stats.totalOngs.toString(), 'ONGs cadastradas'],
      [Icons.people_alt, _stats.totalDoadores.toString(), 'Doadores'],
      [Icons.campaign, _stats.totalNecessidades.toString(), 'Necessidades'],
      [Icons.handshake, _stats.totalMatches.toString(), 'Conexões (matches)'],
      [
        Icons.attach_money,
        'R\$ ${_stats.valorTotalDoado.toStringAsFixed(0)}',
        'Doado via PIX'
      ],
      [Icons.fact_check, _stats.totalPrestacoes.toString(), 'Prestações de contas'],
    ];

    return _conteudo(
      cor: Colors.white,
      child: Column(
        children: [
          _tituloSecao('Transparência em números',
              'Dados públicos da plataforma, atualizados em tempo real.'),
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
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icone, color: AppColors.primary, size: 34),
          const SizedBox(height: 12),
          Text(
            numero,
            style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            rotulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
        ],
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
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(22),
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
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            papel,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.primary),
          ),
        ],
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            e[1],
                            style: GoogleFonts.poppins(
                                color: Colors.black54, height: 1.5),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      );

  // ------------------------------------------------------------ RODAPE
  Widget _rodape() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0E1A14),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
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
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Projeto Integrador • COTIL / UNICAMP • 2026',
                style: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Feito com 💚 para causar impacto social.',
                style: GoogleFonts.poppins(
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

class _AppBarTopo extends StatelessWidget {
  final VoidCallback onEntrar;
  const _AppBarTopo({required this.onEntrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.volunteer_activism,
                      color: AppColors.primary, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Connect ONG',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B2B22)),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: onEntrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                child: const Text('Entrar'),
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
    return Container(
      width: 320,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icone, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: GoogleFonts.poppins(
                fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style:
                GoogleFonts.poppins(color: Colors.black54, height: 1.55),
          ),
        ],
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
    return Container(
      width: 300,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              numero,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style:
                GoogleFonts.poppins(color: Colors.black54, height: 1.55),
          ),
        ],
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
    return Container(
      width: 230,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ODS $numero',
            style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          Text(
            titulo,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2),
          ),
        ],
      ),
    );
  }
}
