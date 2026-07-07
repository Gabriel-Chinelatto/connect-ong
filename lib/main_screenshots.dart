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

import 'doador/chat_screen.dart';
import 'doador/configuracoes_screen.dart';
import 'doador/doar_pix_screen.dart';
import 'doador/main_shell.dart';
import 'doador/meus_matches_screen.dart';
import 'doador/perfil_publico_doador_screen.dart';
import 'doador/perfil_publico_ong_screen.dart';
import 'models/usuario_logado.dart';
import 'services/api_service.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

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
  runApp(_HarnessApp(tela: tela));
}

class _HarnessApp extends StatelessWidget {
  final String tela;
  const _HarnessApp({required this.tela});

  @override
  Widget build(BuildContext context) {
    // 'contraste' renderiza a mesma tela de Configuracoes com o tema de alto
    // contraste, para provar visualmente que ele muda (feedback do usuario).
    final contraste = tela == 'contraste';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(altoContraste: contraste),
      home: _telaPorNome(tela),
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
      case 'home':
      default:
        return const MainShell();
    }
  }
}
