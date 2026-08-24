---
name: connect-ong-conferencia-final-2026-08-24
description: "Conferencia da ultima semana antes da FECITEC (7 dias): o notebook da feira estava ATRAS do remoto (correcoes do grupo em 20/08), artefatos da pasta FEIRA ESCOLA reconstruidos do codigo novo, e o 501 do site era o Wondershare NativePush agarrando a porta 8090"
metadata:
  node_type: memory
  type: project
originSessionId: 55296eb6-8279-4787-a454-d6bfcfaa4661
---

# Conferencia final — 24/08/2026 (faltam 7 dias p/ a FECITEC 31/08)

O usuario pediu para conferir se TUDO esta 100% na ultima semana. Diagnostico +
correcoes abaixo. Ver tambem [[connect-ong-ia-modelo-aposentado-2026-08-20]] e
[[connect-ong-feira-escola-2026-08-13]].

## 🔴 O notebook da feira estava DESATUALIZADO (a descoberta principal)

Durante a semana de testes o grupo (com o Claude, ~20/08) achou e corrigiu coisas
sérias e empurrou pro remoto. Este notebook estava ATRAS: mobile 2, web 1,
backend 3 commits. **O jar/builds da pasta FEIRA ESCOLA eram anteriores a essas
correcoes** — em especial a IA (modelo aposentado) e o painel (guarda de saida).

O que entrou (pull feito, ff-only, sem perder nada; minhas mudancas locais do
backend eram uma versao ANTIGA da Dora — o remoto ja tinha superset, entao
`git stash` + drop):
- Backend: `9bf90c0` Cidade-UF (minha, ja no remoto) + `83d3ce4` **IA de volta ao
  ar (modelo Groq aposentado)** + `b0136f7` Dora "perto vale mais que
  urgente-do-outro-lado-do-pais". Novo `IaController` com `GET /ia/status`.
- Web: `611d561` serve.py nao sobe por cima de outro programa (o 501).
- Mobile: so memoria/docs (COMO-MOSTRAR + memorias) — SEM codigo Dart.
- Desktop: guarda de saida nos formularios da ONG (commit 10:49, DEPOIS do build
  das 10:46 → o painel da pasta estava sem a guarda).

## ✅ Artefatos RECONSTRUIDOS do codigo sincronizado (24/08)

- **jar** (`mvn clean package`): **191 testes verdes**, 0 falhas. `/ia/status`
  agora responde com a cadeia `gpt-oss-120b, gpt-oss-20b, qwen3.6-27b` — prova
  que a correcao da IA esta no jar. INICIAR-FEIRA ja aponta pra esse jar.
- **doador web** e **painel web**: `flutter build web --release
  --dart-define=API_BASE=http://127.0.0.1:8080`. Painel agora COM a guarda.
- APKs NAO precisaram: o codigo Dart do mobile nao mudou desde os builds (so
  docs). Phone=Render, emulador=127.0.0.1, ambos ja com INTERNET+cleartext.

## ✅ Verificado AO VIVO (stack local, aquecido)

- 5 servicos sobem pelo INICIAR-FEIRA; telas 0,03–0,26s.
- `/ia/status` presente; sem chave local → `modo:"regras (sem chave)"` (esperado).
- Dora regras: "sou de campinas"→Campinas-SP, "rio de janeiro"→RJ. OK.
- Chat do desenvolvimento: **"como funcionam os matches?" NAO e mais recusado**
  (a correcao do plural pegou). OK.
- RESTAURAR-DEMO: 424 pendentes → aceitei todos (0) → restaurei → 423. OK.
- Mapa offline: **1.487 tiles** em cache (18 MB).

## 🐛 O "HTTP ERROR 501" do site (porta 8090) — CAUSA REAL nesta maquina

Nao era so o gotcha do SO_REUSEADDR: **o `WsToastNotification.exe` do
`Wondershare NativePush`** (`%LOCALAPPDATA%\Wondershare\Wondershare NativePush\`)
agarra a porta 8090 e responde 501 pra tudo. O serve.py corrigido detecta e se
RECUSA a subir (fez certo), mas ai quem responde o navegador e o intruso. Pior: o
`INICIAR-FEIRA` tinha `if 8090 LISTENING -> pula o site` (achava que ja tinha
subido). **Correcao:** o INICIAR-FEIRA.bat agora roda
`taskkill /IM WsToastNotification.exe /F` ANTES de subir o site (o processo nao e
essencial — so avisos de programas Wondershare; ele relanca sozinho quando
precisar). Depois disso serve.py pega a 8090 normalmente. ⚠️ Se o 501 voltar,
conferir de novo quem esta na 8090 (`netstat -ano | findstr :8090`) — pode ser
outro programa; a saida definitiva seria mudar a porta do site.

## Pendencias RESOLVIDAS na sessao de 24/08 (tarde)

1. **✅ IA de verdade LIGADA.** O usuario gerou uma chave Groq NOVA (a antiga nao
   da p/ revisualizar no console) e colou. Escrita em `FEIRA ESCOLA\chave-ia.txt`
   (fixada always-local; NAO e repo, entao nao vaza p/ git). Provado ao vivo:
   `/ia/status?ping=true` → `chaveConfigurada:true, ping:ok, modo:ia,
   ultimoModeloOk:gpt-oss-120b`; Dora e chat do dev conversando em `modo:ia`. E o
   **fluxo real** (PARAR+INICIAR-FEIRA lendo a chave-ia.txt) tambem foi validado.
   ⚠️ **Pegadinha "Groq × Grok":** o usuario colou 1o uma chave `xai-...` (xAI/Grok,
   PAGA) por engano — nao serve (o projeto usa api.groq.com, chave `gsk_`, gratis).
   A chave `gsk_` certa e a que ficou. (Ambas as chaves ficaram no historico do
   chat; a `xai-` esta sem uso — o usuario pode apaga-la no console da xAI.)
2. **✅ Fotos reais das 6 ONGs da feira** (ids 20/32/33/34/35/36): capas livres do
   Wikimedia Commons (baixadas com User-Agent proprio — o Commons bloqueia o UA
   padrao do curl), escolhidas por causa (idosos→casarao, criancas→sala de aula,
   animais→resgate c/ filhote, doacao→cesta de latas, rua→refeitorio, acolhimento
   →casarao). Gravadas no banco LOCAL via `subir_fotos.py --host 127.0.0.1
   --usuario feira --senha feira123` (precisa `pip install pymysql pillow`).
   Provado: capa da Lar Viva servida pela API. Originais preservados em
   `interno/fotos-ongs/capa/<id>.jpg`. **NAO** foram gravadas no banco da escola
   (produacao intocada). Para nao sumirem no `ATUALIZAR-BANCO`, esse .bat agora
   **re-aplica as fotos automaticamente** apos recopiar (passo [3/3]).

## Pendencias que ficam (decisao do usuario)

- **APK no celular:** dispensado — "so o emulador basta".
- **Rotacionar a senha do MySQL:** o usuario decidiu **NAO** ("a senha e ruim de
  alterar, deixa essa mesma"). Fica exposta no historico do git publico; risco
  aceito conscientemente.
- **Fotos no site publicado (Render):** nao feitas (so local). Se quiser as capas
  no site do ar tambem, rodar `subir_fotos.py` sem `--host` (vai p/ a escola).
- Vespera: `ATUALIZAR-BANCO-DA-ESCOLA.bat` (agora ja re-aplica as fotos).
