/// Histórico de versões (changelog) do Connect ONG.
///
/// Fonte única de verdade da seção "Versões" do portal institucional
/// (`lib/web/portal_institucional_screen.dart`). A primeira da lista é a mais
/// recente; a marcada com [atual] recebe o selo "Atual" e abre expandida.
class VersaoApp {
  /// Rótulo curto da versão, usado no badge (ex.: 'v1.7').
  final String numero;

  /// Título da versão (ex.: 'Assistente com Inteligência Artificial').
  final String titulo;

  /// Versão atual do app (destaque + selo "Atual" + expandida por padrão).
  final bool atual;

  /// Lista do que foi feito nessa versão (bullets).
  final List<String> mudancas;

  const VersaoApp({
    required this.numero,
    required this.titulo,
    required this.mudancas,
    this.atual = false,
  });
}

/// Changelog do Connect ONG — da mais recente (topo) para a mais antiga.
const List<VersaoApp> kVersoesApp = [
  VersaoApp(
    numero: 'v1.8',
    titulo: 'Revisão final de segurança',
    atual: true,
    mudancas: [
      'Sessão protegida: se o acesso expirar, o app volta ao login '
          'automaticamente, sem telas travadas',
      'Privacidade real em toda a busca: telefone e e-mail da ONG só '
          'aparecem quando ela permite',
      'Modo demonstração desligado por padrão (ligado só no computador da feira)',
      'Proteção contra abuso reforçada: limite por origem real de acesso '
          'em contribuições, cadastro e recuperação de senha',
      'Contas encerradas não conseguem mais renovar o acesso',
      'App mais robusto: leitura de dados tolerante a formatos, evitando '
          'travamentos',
    ],
  ),
  VersaoApp(
    numero: 'v1.7',
    titulo: 'Assistente com Inteligência Artificial',
    mudancas: [
      'Dôra, assistente de doação com IA gratuita que conversa e recomenda '
          'ONGs reais',
      'Análise de foto: envie uma imagem do que quer doar e a IA identifica e '
          'sugere ONGs',
      'Histórico de conversas estilo ChatGPT (criar, buscar, fixar, renomear, '
          'excluir)',
      'Localização adaptável (entende a cidade ou o bairro que você mencionar)',
      'Memória do seu histórico de doações ("com base no que você já doou...")',
      'Enviar com Enter e Shift+Enter para nova linha em todos os chats',
    ],
  ),
  VersaoApp(
    numero: 'v1.6',
    titulo: 'Tempo real & Segurança extra',
    mudancas: [
      'Matches e interesses em tempo real (a ONG vê o interesse na hora; o '
          'doador vê o aceite na hora)',
      'Verificação em duas etapas (2FA) no login',
      'Alterar e-mail com confirmação de senha',
      'Agrupamento de doações por doador no painel da ONG',
      'Edição de necessidades; conversas concluídas viram histórico',
    ],
  ),
  VersaoApp(
    numero: 'v1.5',
    titulo: 'Comunidade & Controle',
    mudancas: [
      'Bloqueio de doador (estilo WhatsApp)',
      'Privacidade real (exibir ou ocultar telefone e e-mail)',
      'Seleção de Estado e Cidade com base no IBGE (offline)',
      'Detalhe da necessidade e "demonstrar interesse novamente"',
      'Acessibilidade real: alto contraste e navegação simplificada',
      '"Como chegar" e endereço no Google Maps',
    ],
  ),
  VersaoApp(
    numero: 'v1.4',
    titulo: 'Experiência renovada',
    mudancas: [
      'Redesenho completo do app do doador (Início viva, navegação em 5 abas)',
      'Matches em 3 abas (Ativas, Aguardando, Concluídas)',
      'Perfil público do doador com avaliação estilo Uber',
      'Prestação de contas rica (fotos e valor utilizado) com prazo de 10 dias',
      'PIX simulado em 2 fases e streak do Top 1 no ranking',
      'Chat estilo WhatsApp (visto, online, digitando, reações e anexos)',
    ],
  ),
  VersaoApp(
    numero: 'v1.3',
    titulo: 'Segurança & Conformidade',
    mudancas: [
      'Login com JWT e autorização por dono (correção de falhas de acesso)',
      'LGPD (política de privacidade, termos e consentimento) e papel de '
          'administrador',
      'Exclusão segura de conta (soft-delete)',
      '"Esqueci a senha" e limite de tentativas (proteção contra força bruta)',
    ],
  ),
  VersaoApp(
    numero: 'v1.2',
    titulo: 'Engajamento & Doações',
    mudancas: [
      'Feed inteligente com busca e filtros',
      'Campanhas de arrecadação',
      'Doação financeira via PIX (simulado)',
      'Timeline de atividades, Mural de impacto, Ranking de transparência, '
          'Conquistas e Favoritos',
      'Relatórios em PDF',
    ],
  ),
  VersaoApp(
    numero: 'v1.1',
    titulo: 'Confiança & Transparência',
    mudancas: [
      'Verificação de ONG (selo)',
      'Prestação de contas das doações',
      'Avaliações das ONGs',
      'Central de notificações',
    ],
  ),
  VersaoApp(
    numero: 'v1.0',
    titulo: 'Fundação & Match',
    mudancas: [
      'Cadastro de doadores e ONGs',
      'Publicação de necessidades',
      'Match entre doador e ONG (interesse e aceite)',
      'Chat entre as partes',
      'Painel de impacto, perfil e configurações',
    ],
  ),
];
