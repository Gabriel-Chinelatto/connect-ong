---
name: connect-ong-paginacao-2026-09-01
description: "Vespera da apresentacao: rolagem infinita na busca de ONGs (web e mobile) com paginacao opcional no GET /ongs, o assistente que morria depois de 1-2 perguntas por causa da validacao do historico, e os numeros errados que ele contava para os avaliadores"
metadata:
  node_type: memory
  type: project
---

# Paginacao e correcoes da vespera — 01/09/2026

Rodada disparada por dois retornos do professor + um relato do usuario. Ver
tambem [[connect-ong-imagens-demo-2026-08-25]], que criou parte do problema
(as 2.000 ONGs ilustradas).

## 🐛 O assistente morria depois de 1-2 perguntas (nao era a IA)

Sintoma: "O assistente esta indisponivel no momento" na tela Sobre o
Desenvolvimento e na Dora, sempre depois das primeiras respostas. **Nao era
falha da IA — era VALIDACAO.**

Cada item do historico tinha `@Size(max = 1000)`. As respostas do assistente tem
**1.500 a 2.500 caracteres**, e o front devolve o historico a cada pergunta:
a resposta ANTERIOR estourava a validacao, a API devolvia **400** e o cliente
traduz qualquer nao-2xx como "indisponivel". Reproduzido: a 1a resposta veio com
1.590 chars e a 2a pergunta ja falhou.

O erro de fundo: **tratar como ABUSO um dado que o proprio sistema gerou.** Um
limite de conversa deve **CORTAR**, nunca recusar.

- `MensagemHistorico.textoParaIa()` corta cada troca em **700** chars; os dois
  services (Dora e dev) usam.
- `@Size` por item: 1.000 → **20.000** (so teto contra abuso).
- `@Size` da lista: 20 → **40** (com 20, conversa de +10 perguntas era recusada
  se o cliente mandasse tudo; os apps ja cortam em 8).

700 tambem estica a cota: o historico viaja em TODA pergunta e a Groq gratuita
da **8.000 tokens/min POR MODELO**. Medido em rajada de 14 perguntas em 10 s:
antes 7 com IA + um 400; depois **9 com IA e zero erro**. Em ritmo humano
(~18 s entre perguntas), responde tudo com IA.

## 🐛 O assistente contava numero ERRADO para os avaliadores

Ele dizia "165 testes no backend, ~90 no mobile". O real e **191 / 101 / 52 =
344**. Corrigido em `resources/dev/conhecimento_dev.md`, junto com: Liquibase
**59** changesets (dizia 58) e os **modelos da IA** (dizia `llama-3.1-8b-instant`;
hoje e a cadeia `gpt-oss-120b` → `gpt-oss-20b` → `qwen3.6-27b`, visao no qwen).
Secao nova sobre logo/capa + regra de performance nº 3 + v2.3.

⚠️ **Licao:** o documento do assistente e a boca do projeto na banca. Numero
desatualizado ali vira numero errado dito em voz alta.

## ⚡ Rolagem infinita na busca de ONGs (pedido do professor)

A aba travava. Duas causas, a segunda pior:

1. Baixava as **2.000 de uma vez**. No app, criar 2.000 objetos trava a thread
   da interface; na **web era pior** — montava as 2.000 cards no mesmo
   `innerHTML` (~4.000 `<img>` no documento).
2. **Refazia tudo a cada tecla**: o filtro rodava sobre as 2.000 por letra.

### Backend — paginacao OPCIONAL

    GET /ongs?pagina=0&tamanho=24
    GET /ongs?nome=lar+viva&pagina=0&tamanho=24

Sem os parametros o comportamento e **exatamente** o de antes (o painel e outras
telas consomem a mesma rota sem paginar). `nome` passou a casar **nome OU
cidade** — era o que o filtro local do app fazia; a busca so mudou de lugar.
Teto de 100 por pagina. Usa a mesma projecao enxuta + `Pageable`.

⚠️ **REGRA DO FIM DA LISTA:** o cliente para quando recebe pagina **VAZIA**, nao
quando recebe menos itens do que pediu. O filtro de ONGs que bloquearam o doador
roda **DEPOIS** de paginar, entao uma pagina cheia no banco pode chegar menor —
parar por tamanho cortaria a lista no meio sem ninguem perceber.

### Web (`js/app.js`) — a prioridade que o usuario pediu

24 por vez + `IntersectionObserver` com 600px de folga na sentinela `#fim-ong`.
Cards **acrescentados** com `insertAdjacentHTML` (o que ja esta na tela nao e
refeito). Busca no servidor com 400 ms de debounce. Contador `buscaId` descarta
resposta atrasada.

Cuidados para nao quebrar o resto:
- **`state.ongs` NAO e mais preenchido pela aba** — mapa, comparador e Ctrl+K
  precisam da lista inteira e ja a pedem por conta propria.
- O hover do card procura primeiro em `listaOngs.itens`, depois em `state.ongs`.
- Favoritar nao repinta mais a aba (perderia a rolagem); a estrela ja era
  trocada no lugar.
- `ligarHoverOng` so pega `.ong-card:not([data-hover])`, senao cada pagina
  duplicava listener.

### Mobile (`buscar_receptor_screen.dart`)

20 por vez, `ScrollController` pedindo a proxima a 600px do fim, debounce de
400 ms, `dispose()` (o Timer e os controllers vazavam). A lista completa deixou
de existir na memoria.

### Medido

| | antes | depois |
|---|---|---|
| Carga da aba | 2.000 ONGs, 1,23 MB | 20–24 ONGs, **11 KB** |
| Tempo | 168 ms | **10–28 ms** |
| Digitar | refiltra 2.000 por tecla | 1 chamada ao servidor |

Web (navegador real): DOM cresce 24 → 48 → 72 → 96. Emulador: abre instantaneo,
contador vai de 20 a 60 sozinho ao rolar, busca "pat" ja traz "Instituto Amigos
de Quatro Patas" enquanto digita.

## 🐛 Erro que EU introduzi e corrigi na mesma rodada

O chip do topo dizia **"20 ONGs encontradas"** — o numero CARREGADO, nao o total.
Com 2.000 no banco, na feira pareceria busca quebrada. Agora: `_temMais`
→ "20 ONGs · role para ver mais"; no fim, o total de verdade.

## ⚠️ APK quebrado quase foi para a pasta da feira

O Gradle **falhou** (`assembleRelease failed`) mas deixou um APK de **41 MB so
com x86_64** (sem ARM) — e eu cheguei a copiar para a pasta. Recompilando deu
**58,6 MB com arm64-v8a + armeabi-v7a + x86_64**. Licao: **conferir o APK antes
de copiar** — `unzip -l` e olhar `lib/`, e comparar o tamanho com o anterior.
Causa provavel: dois `flutter build` concorrentes.

## Estado no fim do dia

- 4 repos commitados e no GitHub. Backend **191**, doador **101**, painel **52**.
- Artefatos da feira reconstruidos: jar, doador web, APK (58,6 MB, 3 ABIs).
- Web e estatico: a mudanca ja vale sem recompilar nada.

## 📌 O QUE FALTA (proxima fila)

1. **`/necessidades` e a proxima**: devolve **7.076 itens, 2,68 MB** de uma vez
   (aba Explorar). Usa `ListView.builder`, entao nao monta tudo na tela — mas o
   *parse* dos 7 mil objetos pesa ao abrir. Mesma receita: `?pagina&tamanho` +
   rolagem infinita. **Nao foi feito de proposito**: seria a segunda mudanca de
   risco na vespera.
2. **Paginar tambem o mapa/comparador da web?** Nao — eles PRECISAM da lista
   inteira. Se um dia pesar, a saida e um endpoint enxuto so com id/nome/coord.
3. **Validacao com ONG real** continua sendo a informacao que falta para a
   apresentacao (ver [[connect-ong-imagens-demo-2026-08-25]] e o roteiro).
4. **`CONFERIR.bat`** (ideia da retrospectiva): um comando que checa IA, imagens,
   tempos e contagem de testes antes de apresentar. Quatro dos ultimos cinco bugs
   silenciosos teriam sido pegos por ele.
