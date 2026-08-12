---
name: connect-ong-ajustes-pos-recheio-2026-08-12
description: "Rodada de 12/08/2026 - os tres problemas que o banco cheio revelou na TELA (carrossel estourando, campanha sem caminho para o perfil da ONG, mapa ilegivel com 2.000 pinos) e como rodar os quatro servicos locais para conferir"
metadata: 
  node_type: memory
  type: project
  originSessionId: 01999f4b-11a0-40ba-a799-57d84627ae96
  modified: 2026-08-12T14:44:53.327Z
---

# Rodada de 12/08/2026 — ajustes que só apareceram com o banco cheio

Contexto: no dia anterior o banco foi recheado (ver
[[connect-ong-massa-demo-e-feira-2026-08-11]]). O usuário pediu "rode para eu
conferir", subimos os quatro serviços locais, ele olhou na tela e mandou três
prints com problemas. Todos corrigidos, commitados e publicados.

Commits: mobile `5f23911` · web `2d72b07`. Testes do doador: **98 verdes**
(96 antes), `flutter analyze` limpo.

## 1. O carrossel de campanhas estourava a tela (1.381 pixels)

O print mostrava a faixa amarela e preta de "RIGHT OVERFLOWED BY 1381 PIXELS"
embaixo do carrossel da Início. A causa não era o card: era o **indicador de
páginas**, que desenhava **uma bolinha por campanha**
(`lib/widgets/cards/carrossel_campanhas.dart`, método `_indicador`). Com 7
campanhas cabia; com o banco cheio a Início passou a receber TODAS as campanhas
abertas da plataforma (centenas) e a linha de bolinhas passou da largura da tela.

Duas correções:
- As bolinhas viraram uma **janela deslizante de no máximo 7** (`_maxPontos`),
  com o total escrito ao lado ("3 de 60"). Não estoura com 5 nem com 500.
- A Início voltou a ser **vitrine**: `inicio_tab.dart` corta em **10 campanhas**
  (as `destaque` primeiro) e "Ver todas" abre a lista completa, que já existia.
  Antes eram centenas de cards para deslizar um a um.

Travado em `test/carrossel_campanhas_test.dart`: um teste renderiza **60
campanhas** e falha se o overflow voltar (overflow de layout vira exceção em
teste de widget). ⚠️ Ao tocar em algo dentro de um `PageView`, o finder pode
achar a página VIZINHA (construída, mas fora da tela): usar
`find.text(...).hitTestable().first`, senão o tap erra o alvo.

## 2. Da campanha não havia caminho para o perfil da ONG

Pedido do usuário: "que através das campanhas eu consiga entrar no perfil da
ong". O nome da ONG dentro do card era texto morto. Agora é um atalho (verde,
com seta) que abre `PerfilPublicoOngScreen`, no carrossel da Início
(callback novo `onTapOng`) e na lista `campanhas_screen.dart`. O toque no nome
não dispara o toque do card, que continua levando à campanha.

## 3. O mapa da web com 2.000 pinos era ilegível

O usuário: "por agora estar com muitas ongs ficou muito poluído... algo passar
mouse por cima mostre (SP: 57 ongs)". Era isso mesmo: o mapa desenhava um pino
por ONG e o Brasil virava uma mancha laranja.

Ficou em **três níveis** (`js/app.js`, dentro de `viewMapa`):

| Zoom | O que aparece |
|---|---|
| `< 7` (`ZOOM_ESTADO_ATE`) | uma bolha por **estado** com a contagem ("448 SP"); hover mostra "São Paulo: 448 ONGs" (nomes em `UI.NOME_UF`, novo em `js/ui.js`); clique aproxima no estado |
| `7` a `11` | bolhas **por ÁREA**, com passo `98 / 2^zoom` — calculado para cada bolha ocupar ~70px na tela, então a leitura é igual de longe ou de perto; a dica lista as cidades da bolha |
| `>= 12` (`ZOOM_DETALHE`) | pino de cada ONG, **só os da área visível** |

🔴 **Agrupar por CIDADE foi tentado e NÃO resolve** — são 1.414 cidades
distintas, quase todas com 1 ou 2 ONGs, e a tela continuava coberta. Foi por isso
que virou agrupamento por área. Não repetir a tentativa.

Detalhes que custaram tempo:
- O mapa abria em **Limeira com zoom 8** (fazia sentido com 20 ONGs da região);
  agora abre no **Brasil inteiro** (`setView([-14.8, -52.5], 4)`), e o botão de
  recentrar volta para essa visão.
- `pintar()` chamava `fitBounds` sempre; com repintura por `zoomend/moveend` isso
  brigaria com o zoom do usuário. Agora `pintar(termo, enquadrar)` só reenquadra
  quando pedido (carga inicial, busca, recentrar).
- Bolhas grandes demais **escondiam** PB/AL/SE atrás de PE. Tamanho ficou numa
  faixa estreita (`min(46, 26 + sqrt(n)*2.2)`) e os grupos MENORES são
  desenhados por último, para ficarem por cima.
- Estilo `.co-bolha-uf` em `css/styles.css`.

Medido antes de mudar: **2.000 marcadores Leaflet renderizam em 87 ms** (Chrome
headless) — o problema era legibilidade, não desempenho.

## Como rodar os quatro serviços para conferir na tela

```bash
# 1) Backend (porta 8080) — usa o banco da escola
cd "connect-ong-api/API - Chinelatto - att2/API - Chinelatto/API - Chinelatto"
./mvnw.cmd -B spring-boot:run -Dspring-boot.run.profiles=local

# 2) App do doador (5000) e 3) Painel da ONG (5001)
flutter run -d chrome --web-port=5000 --dart-define=API_BASE=http://localhost:8080
flutter run -d chrome --web-port=5001 --dart-define=API_BASE=http://localhost:8080

# 4) Site em HTML (8090, com proxy para a API local)
cd connect-ong-web-main && python serve.py 8090 http://localhost:8080
```

⚠️ **Abrir o site por `http://127.0.0.1:8090`, NÃO por `localhost`.** O
`serve.py` escuta só em IPv4 (`0.0.0.0`) e no Windows o `localhost` resolve para
`::1` primeiro: a conexão é recusada e só depois cai para IPv4. Medido: **2,1s
por requisição** por `localhost` contra **0,1s** por `127.0.0.1` (o Tomcat do
backend não sofre disso, ele escuta nas duas pilhas). Isso vale para o
`INICIAR-FEIRA.bat` — corrigir o atalho quando preparar a máquina da feira.

⚠️ Ao rodar `mvnw`/`flutter run` em segundo plano, **não usar `| tail`**: o pipe
segura a saída inteira até o processo terminar e o log fica vazio. Redirecionar
para arquivo (`> arquivo.log 2>&1`) e esperar pela linha
`Started ConnectongApiApplication`.

💡 Para conferir uma tela da web que exige login sem navegador interativo: criar
uma página temporária na pasta do site que faz `fetch('/usuarios/login')`, grava
`co_token`/`co_user` no `localStorage` e redireciona para a rota — mesma origem,
funciona no Chrome headless com `--screenshot`. Apagar depois.

## 4. A tela de LOGIN do doador (mesmo dia, mais tarde) — commit `421c1e7`

O usuário mandou o print do login: "meio feia ainda... esses dados ficam meio
repetitivos". Os "dados" eram os **números da plataforma** (2000 ONGs /
`R$ 3566555` / 7075 causas) que o herói do login buscava em
`/publico/estatisticas`. Ele estava certo por dois motivos: o **portal
institucional é a tela ANTERIOR ao login** (`main.dart`:
`home: kIsWeb ? EntradaWeb() : SplashDecider()`) e já mostra os três números —
lá com `formatarReais` (`portal_institucional_screen.dart:300-307`) — enquanto o
login imprimia `toStringAsFixed(0)`, ou seja, `R$ 3566555` cru. Os números
saíram do login **junto com a chamada de rede que só alimentava aquela linha**.

O pedido foi explícito: **só aparência, nenhuma funcionalidade**. O que mudou em
`lib/pages/login_page.dart` (mesmos campos, mesmo fluxo login/2FA, mesmos
destinos, mesma flag do Modo Feira):
- Degradê profundo (verde vivo → `primaryDark`) no lugar do
  `primaryLight → primary`. O topo claro deixava o texto branco **lavado**; o
  contraste agora é forte na coluna inteira.
- Três círculos translúcidos de fundo, todos em **`IgnorePointer`** — sem isso
  um enfeite decorativo pode comer o toque do formulário.
- Marca em moldura circular; o `logo.jpg` é **500x500 com margem branca**, então
  `BoxFit.contain` num círculo deixava o emblema minúsculo. Ficou
  `BoxFit.cover` preenchendo o círculo (o fundo branco do JPG some no branco da
  moldura, o `ClipOval` corta só o canto).
- Campos que acendem no foco (borda/ícone verdes, halo) via dois `FocusNode`
  com listener que só repinta — não mexe na navegação por teclado.
- Card do Modo Feira virou vidro translúcido sobre o verde, para não competir
  com o cartão branco do login. Credenciais continuam `SelectableText`.

⚠️ **Chrome headless no Windows tem largura MÍNIMA de janela (~500px).** Pedir
`--window-size=430,940` não dá uma viewport de 430: o Flutter continua
diagramando em ~500 e o print sai **cortado à direita** (o cartão passa da borda
e parece bug de layout, mas não é). Usar `--window-size=502,...` para cima. O
harness ganhou a rota **`#login`** — a única que **pula** o login demo do
`main_screenshots.dart`, já que a tela precisa da sessão vazia.

⚠️ **`git commit -m` com here-string do PowerShell quebra se a mensagem tiver
aspas duplas**: o git recebe os pedaços como pathspec e falha. Escrever a
mensagem num arquivo e usar **`git commit -F arquivo.txt`**.

## Estado ao fim da sessão

Os quatro serviços ficaram **rodando** (backend 8080, doador 5000, painel 5001,
site 8090) para o usuário conferir. Num chat novo, ou eles já morreram com a
sessão, ou é só liberar as portas:
`Get-NetTCPConnection -LocalPort 5000 -State Listen | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }`.

A pasta solta `connect-ong/connect-ong-web/` (clone órfão, oferecido para apagar
várias vezes) entrou no `.gitignore` do repo mobile depois de um `git add -A`
tê-la commitado por engano como repositório embutido. **Ela continua no disco** —
apagar ainda é uma decisão do usuário.
