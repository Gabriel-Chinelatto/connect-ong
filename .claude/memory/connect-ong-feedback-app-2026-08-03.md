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
- Enquanto a API não responde o portal mostra **"—"** em vez de "0" (ver a seção da hibernação
  do Render, abaixo).
- Portal envolvido no próprio `Theme(AppTheme.light(...))`: ele já era claro por decisão, mas
  agora nenhum texto pode herdar o branco do tema escuro e sumir.
- "Sobre o Projeto" listava funcionalidades da v1.0 (cadastro/busca/gerenciamento) → trocada
  pelo que o app faz hoje (match+chat, PIX+prestação, Dora, ranking, frete/mapa, acessibilidade).

## 🔴 Hibernação do Render — causa do "TimeoutException" (commit `5f5c4e2`)

Ao rodar os três apps para o usuário ver, ele abriu o mobile e levou
**"TimeoutException after 0:00:12: Future not completed"** na tela de login, e o portal ficou
sem os números. **Não era a API quebrada.** Medições desta sessão:

| situação | tempo |
|---|---|
| 1ª chamada com o Render dormindo | **95 s** (uma vez deu 9,7s, outra estourou 90s) |
| chamadas seguintes, servidor quente | **0,7 s** |
| login quente | 2,3 s |

O plano gratuito do Render **desliga o serviço após ~15 min sem acesso** e o app usava
**timeout fixo de 12 s** → a primeira tela falhava *sempre*. CORS foi descartado na
investigação: `curl -H "Origin: http://localhost:5000"` volta com
`access-control-allow-origin: http://localhost:5000`.

Correção (vale para o app inteiro, sem tocar em cada chamada):
- **`ApiService.timeout` virou getter adaptativo**: 100 s enquanto a API ainda não respondeu
  nesta sessão (ou não responde há mais de 12 min — janela em que o Render pode ter dormido de
  novo) e 12 s depois que ela provou estar no ar. Funciona porque **todos os serviços leem
  `ApiService.timeout`** (conferido com grep).
- `ApiService.acordarServidor()` no `main`: dispara sem aguardar uma chamada pública barata só
  para tirar o servidor do repouso enquanto a UI aparece.
- `ApiService.registrarResposta()` marca o horário da última resposta — chamado no `_executar`
  central e nos **dois pontos que falam direto com o `http`**: `AuthService.login` e
  `EstatisticaService`.
- A tela de login mostrava `e.toString()` cru (era ela que exibia o "TimeoutException"); passou
  a usar `ApiService.mensagemAmigavel`, que explica a hibernação.
- Regra travada em `test/timeout_adaptativo_test.dart`.

⚠️ **PARA A FEIRA:** o servidor dorme a cada 15 min ocioso. **Abrir o app uma vez antes de
apresentar** para acordá-lo, ou configurar um **UptimeRobot** pingando a API de 10 em 10 min
(ofereci configurar; o usuário ainda não respondeu).

## Como rodar os três apps para o usuário ver

Nenhum precisa do backend local — todos apontam para a API hospedada.

```
# mobile (doador) — porta 5000
cd connect-ong && flutter run -d chrome --web-port=5000

# desktop (painel da ONG) — porta 5001
cd "connect_ong - Desktop" && flutter run -d chrome --web-port=5001

# web (HTML puro) — porta 8090, com proxy same-origin para a API hospedada
cd connect-ong-web-main && python serve.py 8090 https://connect-ong-api.onrender.com
```

Gotchas medidos:
- O `serve.py` aceita **https** como backend (usa `urllib.request.urlopen`), então dá para
  apontar direto para o Render sem subir o Spring.
- Ao matar um `flutter run`, o processo `dartvm` **continua segurando a porta** →
  `Failed to bind web development server ... errno = 10048`. Liberar com
  `Get-NetTCPConnection -LocalPort 5000 -State Listen | Stop-Process -Id $_.OwningProcess -Force`.
- Os dois Flutter rodam em **modo debug**, bem mais lento que o real — não julgar performance
  por ali; comparar com a versão publicada ou gerar build release.

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

## Estado ao fim da sessão

`flutter analyze` limpo, **87 testes verdes**, tudo commitado e no ar:
`8816b01` (rodada de feedback) · `9737054` (memória) · `5f5c4e2` (timeout adaptativo).

**Ofertas feitas que o usuário ainda não respondeu:**
1. Repetir a otimização das fotos no repo **connect-ong-web** (`assets/img/` ainda com 1,4 MB) —
   é o site que a banca abre pelo celular.
2. Apagar a pasta solta `connect-ong/connect-ong-web/` — um clone com o commit `73cec76`
   ("landing page") que **não existe no GitHub** e nada usa.
3. Configurar UptimeRobot para a API não hibernar.

Ver [[connect-ong-endereco-mapa-2026-07-29]] e a regra de performance em
[[connect-ong-tech-guidelines]].
