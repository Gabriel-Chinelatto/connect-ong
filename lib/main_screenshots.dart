// HARNESS DE VERIFICACAO VISUAL (nao entra no app final).
//
// Build:  flutter build web --release -t lib/main_screenshots.dart
// Uso:    servir build/web e abrir  http://localhost:PORTA/#<tela>
//         (Chrome headless tira o print; ver scripts em tool/screenshots)
//
// Faz login REAL como o doador demo (demo.joao / demo123) e abre a tela
// escolhida pelo fragment da URL, para conferir as telas da rodada de UX
// de 2026-07-03 com dados reais do backend.
//
// Telas suportadas (#fragment):
//   home          -> MainShell (aba Inicio: frase, carrossel, impacto)
//   matches       -> Matches aba Ativas
//   concluidas    -> Matches aba Concluidas (historico estilo iFood)
//   pix           -> DoarPixScreen (fluxo 2 fases)
//   perfil-doador -> PerfilPublicoDoadorScreen (estilo Uber)
//   perfil-ong    -> PerfilPublicoOngScreen (capa/streak/Maps/galeria)
//   chat          -> ChatScreen do match 8 (anexo de imagem)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'doador/assistente_screen.dart';
import 'doador/chat_screen.dart';
import 'doador/configuracoes_screen.dart';
import 'doador/doar_pix_screen.dart';
import 'doador/main_shell.dart';
import 'doador/meus_matches_screen.dart';
import 'doador/perfil_publico_doador_screen.dart';
import 'doador/perfil_publico_ong_screen.dart';
import 'screens/about/descricao_screen.dart';
import 'models/usuario_logado.dart';
import 'services/api_service.dart';
import 'services/assistente_service.dart';
import 'services/conversas_dora_service.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';
import 'web/portal_institucional_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Login real do doador demo -> grava token + sessao como o app faria.
  final resp = await http.post(
    Uri.parse('${ApiService.baseUrl}/usuarios/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'demo.joao@connectong.com',
      'senha': 'demo123',
    }),
  );
  final dados = jsonDecode(resp.body) as Map<String, dynamic>;
  await ApiService.setToken(dados['accessToken'] as String?);
  await SessionService().salvarUsuario(UsuarioLogado(
    id: dados['id'] as int,
    nome: dados['nome'] as String,
    email: dados['email'] as String,
    tipo: dados['tipo'] as String,
  ));

  final tela = Uri.base.fragment.isEmpty ? 'home' : Uri.base.fragment;

  // Para as telas da Dora, semeia algumas conversas locais para provar o
  // historico persistente (lista + chat restaurado) sem depender de uso manual.
  if (tela.startsWith('assistente')) {
    await _semearConversasDora();
  }

  runApp(_HarnessApp(tela: tela));
}

/// Semeia conversas de exemplo no storage local da Dora (para a verificacao
/// visual do historico + do chat restaurado).
Future<void> _semearConversasDora() async {
  final s = ConversasDoraService();
  final agora = DateTime.now();

  final roupas = ConversaDora(
    id: 'seed-roupas',
    titulo: 'Tenho roupas para doar',
    fixado: true,
    atualizadoEm: agora,
    mensagens: [
      const MensagemDora(papel: 'user', texto: 'Tenho roupas para doar'),
      const MensagemDora(
        papel: 'assistente',
        texto:
            'Que legal! Perto de voce ha ONGs que recebem roupas. Veja estas '
            'opcoes — e so tocar para abrir o perfil:',
        sugestoes: [
          SugestaoAssistente(
            tipo: 'ONG',
            id: 33,
            titulo: 'Lar Viva',
            subtitulo: 'Sorocaba - SP · recebe roupas e agasalhos',
          ),
          SugestaoAssistente(
            tipo: 'NECESSIDADE',
            id: 45,
            titulo: 'Agasalhos de inverno',
            subtitulo: 'Casa do Caminho',
          ),
        ],
      ),
    ],
  );

  final animais = ConversaDora(
    id: 'seed-animais',
    titulo: 'Quero ajudar animais',
    atualizadoEm: agora.subtract(const Duration(hours: 3)),
    mensagens: [
      const MensagemDora(papel: 'user', texto: 'Quero ajudar animais'),
      const MensagemDora(
        papel: 'assistente',
        texto:
            ' Maravilha! Abrigos de animais costumam precisar de racao, '
            'cobertores e ajuda com castracao. Quer que eu procure um perto '
            'de voce?',
      ),
    ],
  );

  final comoFunciona = ConversaDora(
    id: 'seed-como',
    titulo: 'Como funciona a doacao?',
    atualizadoEm: agora.subtract(const Duration(days: 2)),
    mensagens: [
      const MensagemDora(papel: 'user', texto: 'Como funciona a doacao?'),
      const MensagemDora(
        papel: 'assistente',
        texto:
            'E simples: voce escolhe uma necessidade, demonstra interesse e a '
            'ONG entra em contato pelo chat para combinar a entrega. 💚',
        modoRegras: true,
      ),
    ],
  );

  await s.salvar(comoFunciona);
  await s.salvar(animais);
  await s.salvar(roupas);
  await s.definirUltima(roupas.id); // conversa restaurada ao abrir o chat
}

class _HarnessApp extends StatelessWidget {
  final String tela;
  const _HarnessApp({required this.tela});

  @override
  Widget build(BuildContext context) {
    // 'contraste' renderiza a mesma tela de Configuracoes com o tema de alto
    // contraste, para provar visualmente que ele muda (feedback do usuario).
    final contraste = tela == 'contraste';
    // Sufixo '-dark' força o tema escuro (ex.: 'portal-dark') — usado para
    // provar que o portal continua legível no modo escuro do app.
    final escuro = tela.endsWith('-dark');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: escuro ? AppTheme.dark() : AppTheme.light(altoContraste: contraste),
      home: _telaPorNome(escuro ? tela.replaceFirst('-dark', '') : tela),
    );
  }

  Widget _telaPorNome(String nome) {
    switch (nome) {
      case 'config':
      case 'contraste':
        return const ConfiguracoesScreen();
      case 'matches':
        return const MeusMatchesScreen();
      case 'concluidas':
        final ctrl = MatchesAbaController()..irPara(2);
        return MeusMatchesScreen(abaController: ctrl);
      case 'pix':
        return const DoarPixScreen(ongId: 33, ongNome: 'Lar Viva');
      case 'perfil-doador':
        return const PerfilPublicoDoadorScreen(usuarioId: 18);
      case 'perfil-ong':
        return const PerfilPublicoOngScreen(ongId: 33, ongNome: 'Lar Viva');
      case 'chat':
        return const ChatScreen(
          interesseId: 8,
          meuRemetente: 'DOADOR',
          titulo: 'Fraldas geriatricas',
        );
      case 'chat-historico':
        return const ChatScreen(
          interesseId: 8,
          meuRemetente: 'DOADOR',
          titulo: 'Fraldas geriatricas',
          concluido: true,
        );
      case 'portal':
        return const PortalInstitucionalScreen();
      case 'sobre':
        return const DescricaoScreen();
      case 'assistente':
        return const AssistenteScreen();
      case 'assistente-historico':
        return const AssistenteScreen(abrirHistoricoAoIniciar: true);
      case 'home':
      default:
        return const MainShell();
    }
  }
}
