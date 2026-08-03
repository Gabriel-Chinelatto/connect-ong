---
name: connect-ong-feedback-app-2026-08-03
description: Rodada de feedback do app mobile em 2026-08-03 (portal, documentos legais, foguinho, chat da IA no tema escuro, performance) e o harness de screenshots usado para provar cada correção
metadata:
  type: project
---

Rodada de melhorias no **repo mobile** (`connect-ong`, branch `main`, commit **8816b01**), pedida
pelo usuário a partir de screenshots. Ele começou dizendo "melhorias web" e corrigiu em seguida:
**é o app mobile** — o que confundiu é que a "tela inicial" das capturas é o
`lib/web/portal_institucional_screen.dart`, que **mora no repo mobile** e é a entrada quando o
app roda no navegador (`main.dart`: `home: kIsWeb ? EntradaWeb() : SplashDecider()`).
O site `connectong.netlify.app` é OUTRO projeto (HTML puro, repo `connect-ong-web`).

## O que foi corrigido (e a causa de cada um)

- **Portal com 3 botões de "entrar" colados** → agora um único login ("Entrar" no topo), o herói
  tem "Quero doar" (ação de valor) e "Como funciona" que **rola a página** (âncoras por
  `GlobalKey` + `Scrollable.ensureVisible`). O topo ganhou links Como funciona / Equipe / Versões.
- **Portal estático** → widget `_Elevavel` (MouseRegion + AnimatedContainer) em cada card:
  sobe 5-8px e ganha sombra verde no hover. Cada card é StatefulWidget próprio **de propósito**,
  para o hover não repintar a página inteira.
- **"Versões" desatualizada** → `lib/data/versoes.dart` parava na v1.9. Entraram v2.0, v2.1 e
  **v2.2 (atual)**. Esse arquivo é fonte única: alimenta o portal E a tela "Sobre o Projeto".
- **Política de Privacidade "feita à mão"** → `lib/screens/legal/documentos_legais_screen.dart`
  reescrita no padrão dos apps grandes: capa com gradiente + data, bloco "Em resumo" em linguagem
  simples, **sumário que salta para a seção**, seções numeradas em cards, `SelectionArea`
  (copiar/colar) e botão que alterna Política ↔ Termos sem empilhar tela. Data → **Julho de 2026**
  e todo o texto ganhou acentuação (estava sem acentos).
- **🔥 Número do foguinho invisível** (ele escreveu "OGGUINHO") no card de "ONGs em destaque":
  o card tinha `Row[selo, Flexible(chip), Spacer(), verificada]` — o `Spacer` (tight) e o chip
  (loose) dividiam o espaço livre pela metade, o chip era espremido e o número, que estava num
  `Flexible` com `ellipsis`, era cortado para nada. **Medido no teste: 9,5px para um texto que
  precisa de 24,5px.** Fix: selo + chip num grupo `Expanded`, número rígido no chip e o
  `ellipsis` movido para o rótulo do nível. Regressão travada em `test/chip_foguinho_test.dart`.
- **Texto digitado invisível no chat "Sobre o Desenvolvimento"**:
  `lib/screens/about/desenvolvimento_chat_screen.dart` fixava cores claras
  (`fillColor: AppColors.background`) e o `TextField` **não tinha `style`** → no tema escuro o
  texto herdava o branco do tema sobre campo claro. Tela inteira migrada para `ColorScheme` +
  cor explícita no campo. **Padrão do projeto: todo TextField usa
  `fillColor: cs.surfaceContainerHighest`** — essa tela era a única fora do padrão (conferido
  com grep em todos os `fillColor`).

## Performance ("meio lerdo ao clicar")

- `AppTheme` agora define `pageTransitionsTheme` **para todos os casos** (antes só quando
  "navegação simplificada" estava ligada): fade + micro-deslize de 220ms no lugar do
  `ZoomPageTransitionsBuilder` do M3, que compõe camada extra a cada frame (pesa na web).
- Troca de aba do `MainShell`: 260ms → 200ms e `FadeTransition/SlideTransition` no lugar de
  `AnimatedBuilder + Opacity` (não reconstrói widget por frame).
- `EstatisticaService` ganhou **cache estático de 2 min + deduplicação de chamadas em voo**
  (`cacheAtual` para pintar na hora). Usado por portal, login e Mural. "Puxar para atualizar"
  passa `forcar: true`.
- **Fotos da equipe eram o maior peso**: `gabriel.jpg` era **3024x4032 / 731 KB** para aparecer
  com 90px. Redimensionadas (450x600) e `luan.png` (tem transparência real, continua PNG) →
  `assets/images` caiu de **1,4 MB para 378 KB**; todo `Image.asset` dessas fotos usa `cacheWidth`.
  ⚠️ **O repo da WEB (`connect-ong-web`, `assets/img/`) ainda tem as versões pesadas** — mesma
  otimização vale lá e ninguém fez ainda.

## Achados extras (não reportados pelo usuário)

- Faixa de números do portal quebrava 4+2 (torta) → card de 240→300px dá **3+3** em 1100px.
- Cards Missão/Visão/Valores com alturas diferentes → `minHeight: 230`.
- Valor em PIX usava `toStringAsFixed(0)` → agora `formatarReais` (padrão do app).
- Enquanto a API não responde o portal mostra **"—"** em vez de "0" (o Render hiberna; medido
  **9,7s** de cold start nesta sessão, e pode passar de 30s).
- Portal envolvido no próprio `Theme(AppTheme.light(...))`: ele já era claro por decisão, mas
  agora nenhum texto pode herdar o branco do tema escuro e sumir.
- "Sobre o Projeto" listava funcionalidades da v1.0 (cadastro/busca/gerenciamento) → trocada
  pelo que o app faz hoje (match+chat, PIX+prestação, Dora, ranking, frete/mapa, acessibilidade).

## Como verificar visualmente (vale para as próximas rodadas)

O projeto tem um harness pronto — **use ele em vez de pedir print ao usuário**:
1. `flutter build web --release -t lib/main_screenshots.dart`
2. `dart tool/screenshots/server.dart build/web 5199`
3. `"C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu
   --hide-scrollbars --window-size=1280,5600 --virtual-time-budget=15000
   --screenshot=saida.png "http://127.0.0.1:5199/#portal"`

Rotas por fragment: `home`, `portal`, `sobre`, `matches`, `pix`, `perfil-ong`, `chat`,
`assistente`, `config` e as que entraram nesta rodada: **`privacidade`, `termos`, `chat-dev`**.
Sufixo **`-dark`** força o tema escuro (ex.: `#chat-dev-dark`) — foi assim que o bug do texto
invisível foi provado. ⚠️ O harness faz **login real** no backend antes de renderizar: se o
Render estiver hibernando, o Chrome fica parado esperando — **acorde a API antes**
(`curl https://connect-ong-api.onrender.com/publico/estatisticas`).

Estado: `flutter analyze` limpo, **84 testes verdes**, tudo commitado e no ar.
Ver [[connect-ong-endereco-mapa-2026-07-29]] e a regra de performance em
[[connect-ong-tech-guidelines]].
