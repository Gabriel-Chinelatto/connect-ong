---
name: connect-ong-feira-escola-2026-08-13
description: "Rodada de 13-17/08: pasta FEIRA ESCOLA com RESTAURAR-DEMO (voltar antes entre apresentacoes), Dora modo-regras entendendo Cidade-UF/estados, chave Groq ausente neste notebook, e guarda de saida em TODAS as telas de edicao dos 3 apps"
metadata:
  node_type: memory
  type: project
originSessionId: 55296eb6-8279-4787-a454-d6bfcfaa4661
---

# Rodada FEIRA ESCOLA (13/08/2026, continuada) — 4 pedidos do usuario

Continuacao de [[connect-ong-preparacao-feira-2026-08-13]] (a maquina de
apresentacao ja estava pronta). O usuario pediu 4 coisas ao ver a demo rodando.

## 1. Pasta unica `FEIRA ESCOLA` — na Area de Trabalho REAL (OneDrive)

⚠️ **PEGADINHA (17/08):** a Area de Trabalho do usuario e REDIRECIONADA para o
OneDrive: o caminho fisico e **`C:\Users\gabri\OneDrive\Área de Trabalho\`**, NAO
`C:\Users\gabri\Desktop\` (esse ultimo existe mas nao e o que aparece na tela).
Por isso a pasta criada em Desktop nao aparecia. A `FEIRA ESCOLA` foi MOVIDA para
o OneDrive Desktop (via PowerShell `Move-Item`; o `mv` do bash falha no caminho
com acento/reparse point). Os arquivos foram fixados como "sempre neste
dispositivo" (`attrib +P -U`) para o OneDrive NAO evict-los para nuvem-so e
quebrar na feira — conferido que apk (61 MB) e dump (12 MB) estao fisicamente
presentes. ⚠️ **Os REPOS continuam em `C:\Users\gabri\Desktop\connect-ong` etc.
(fora do OneDrive)** — os caminhos absolutos nos .bat estao certos; so a pasta de
atalhos mudou. Os .bat usam `%~dp0` para achar `interno\` e `chave-ia.txt`, entao
funcionam do novo local (testado: 5 servicos sobem, aquecimento roda).

Tudo o que estava solto na Area de Trabalho foi consolidado nela (os .bat antigos
soltos foram apagados; `INICIAR-FECITEC` ganhou um `_SUPERADO-LEIA.txt`). Conteudo
(+ `PASSO-A-PASSO-DO-DIA.txt` com o roteiro objetivo do dia da feira):
- `INICIAR-FEIRA.bat` (1 clique: MySQL local + jar + doador 5000 + painel 5001 +
  site 8090 + aquecimento; caminhos usam `%~dp0interno\...`, nao mais FEIRA-LOCAL).
- `RESTAURAR-DEMO.bat`, `PARAR-FEIRA.bat`, `RECOMPILAR-FEIRA.bat`,
  `ATUALIZAR-BANCO-DA-ESCOLA.bat`, `LEIA-ME-FEIRA.txt`, `ConnectONG.apk`,
  `chave-ia.txt.EXEMPLO`, e a subpasta `interno\` (dump `banco-escola.sql`,
  `aquecer.py`, logs). Todos os .bat em CRLF (rodar `unix2dos` apos editar).

## 2. RESTAURAR-DEMO.bat = o "botao de voltar antes" (pedido central)

Entre apresentacoes (30+ visitantes), a 1a demo "gasta" o roteiro: aceita os
interesses PENDENTES da Lar Viva, conversa, conclui. `RESTAURAR-DEMO.bat`
reimporta o `interno\banco-escola.sql` no MySQL local (~15s, DROP+recreate feito
pelo proprio dump) e re-aquece — devolve a Lar Viva aos 2 interesses PENDENTES +
necessidades ABERTAS. Testado ao vivo: apos rodar, `interese PENDENTE`=423 de
novo e login da ONG OK. **O usuario da F5 nas abas para recarregar as listas.**
(A demo e 100% LOCAL, entao "bagunçar" nao tem custo — restaura em 15s.)

## 3. Dora (assistente de doacao) — modo REGRAS muito melhor

Sintoma (print do usuario): Dora em "Modo basico" so "jogava ONGs" e nao
entendia cidade. **Causa raiz: a chave do Groq NAO existe neste notebook** (so no
PC da escola; busca no disco inteiro so achou placeholders `gsk_xxx`), entao TODA
IA cai no fallback por regras. E o fallback tinha um bug real: o campo `cidade`
das ONGs guarda **"Cidade - UF"** (nao existe coluna estado — ver
[[connect-ong-deferred]]), mas o codigo comparava a string inteira, entao
"rio de janeiro" nunca casava com "Rio de Janeiro - RJ".

Correcoes em `AssistenteService.java` (backend, so o fallback; a IA real ja
mandava a lista certa):
- `parteCidade()`/`parteUf()`/`mesmoLugar()`/`exibirLugar()`: separam
  "Cidade - UF" e comparam LUGAR (cidade com cidade, ou UF com UF). Todos os
  pontos que faziam `normalizar(o.getCidade())` cru passaram a usar `mesmoLugar`.
- `detectarLocalizacaoNaMensagem` agora reconhece tambem **estado por extenso**
  (mapa `ESTADO_SIGLA`, "no parana" -> sentinel `"UF:PR"`) e **sigla apos
  preposicao** ("em sp"; regex, porque SE/MA/AM/PA/TO sao palavras comuns). "Para"
  (estado) tem regex propria pra nao casar a preposicao.
- Mensagem que **se apresenta com lugar** ("sou de campinas", "moro no rio",
  "se eu estiver...") mesmo SEM gatilho de doacao agora responde com ONGs de la,
  em vez do "nao vou saber responder". Guard: exige um marcador de localizacao
  ("sou de"/"moro"/"estiver"...), senao "qual a capital da Franca?" (existe
  Franca-SP) viraria despejo de cards.
- `ongCitadaNaMensagem`/`respostaNecessidadesDaOng` agora varrem as listas
  COMPLETAS (`ctx.todasOngs/todasNecessidades`), nao o top-20 do recorte — com
  2.000 ONGs a citada quase nunca estava no recorte.
Verificado ao vivo (modo regras): "rio de janeiro"->ONGs do RJ; "sou de
campinas"->Campinas-SP; "no parana"->PR; "capital da Franca?"/"oi"->conversa sem
cards. +4 testes em `AssistenteTest` (29 do pacote Assistente* verdes; suite
backend 183 verde).

**Integracao Groq e CENTRALIZADA e correta**: 8 servicos (Assistente/Dora,
AssistenteDev/chat do desenvolvimento, ItemIa/frete, Redacao, ResumoImpacto,
SobreOng) passam por UM `ProvedorIA` (GroqService), chave unica
`app.ia.groq.key`, com fallback por regras em cada um. Ligar a chave liga TODAS.
`INICIAR-FEIRA.bat` agora le um `chave-ia.txt` opcional (nesta pasta, fora do
Git) e exporta `APP_IA_GROQ_KEY` — colar a chave liga a IA sem recompilar.
⚠️ **Pendencia do usuario: por a chave** (copiar do PC da escola ou gerar nova em
console.groq.com/keys). ⚠️ Nota tecnica: `app.ia.groq.modelo-visao=
qwen/qwen3.6-27b` no application.properties diverge do default do GroqService
(llama-4-scout) — conferir se esse id de visao existe no Groq antes de confiar na
foto; o texto (llama-3.1-8b-instant) esta ok.

## 4. Guarda de saida ("descartar alteracoes?") em TODA tela de edicao

Padrao ja existia (widget `GuardaDeSaida`/`perguntarSaida` em cada app + teste
`guarda_de_saida_test.dart`), mas so cobria editar-perfil e configuracoes.
Agentes varreram os 3 apps e aplicaram no que faltava:
- **Mobile** (`connect-ong`): cadastro doador, cadastrar doacao, esqueci-senha,
  doar PIX (telas de rota, via `GuardaDeSaida`); avaliar ONG e denunciar
  (dialogs, via `PopScope` no conteudo). +3 testes. 101 testes, analyze limpo.
- **Desktop** (`connect-ong-desktop`): criar/editar necessidade, criar campanha,
  prestacao, avaliar doador, trocar email/senha, cadastro de ONG. Novo widget
  `GuardaDeSaidaDialog` (temMudanca como funcao + `canPop:false`, porque digitar
  em dialog nao rebuilda). +2 testes. 52 testes, analyze limpo.
- **Web** (`connect-ong-web`): o listener de `abrirModal` passou a marcar sujo em
  qualquer `[data-avisar-saida]` (nao so `<form>`); atributo adicionado em
  alterar-senha, alterar-email, denuncia, esqueci-senha (forms) e avaliar, PIX
  (divs). ⚠️ A 1a tentativa por heredoc-python FALHOU silenciosamente (o heredoc
  do Git Bash quebrou e o python abriu interativo) — refeito com Edit e conferido
  por grep. Editar doacao/perfil e Ajustes ja tinham. Sem `beforeunload` (fechar
  a aba nunca avisa — decisao mantida).

## APK / mobile no emulador (em andamento 17/08)

⚠️ **DISTINCAO IMPORTANTE:** o `ConnectONG.apk` da pasta foi buildado SEM
dart-define → aponta para o **Render** (nuvem). Logo, num CELULAR real ele NAO
usa o backend local rapido NEM o RESTAURAR-DEMO (fala com o banco remoto da
escola via Render, lento/hiberna). INICIAR-FEIRA e RESTAURAR-DEMO valem para as
telas LOCAIS (web/painel) e para o EMULADOR, nao para o apk-no-celular-via-Render.

**Emulador FEITO e VALIDADO (17/08):** o AVD **`ConnectOng`** (pixel_6) ja existia.
Gerado um **APK apontando para `http://10.0.2.2:8080`** (alias do emulador para o
localhost do host — zero-config, sem `adb reverse`) em
`FEIRA ESCOLA\interno\ConnectONG-emulador.apk`, e o
**`INICIAR-MOBILE-EMULADOR.bat`** (na pasta) sobe o AVD, espera o boot e
INSTALA+abre o app (mais robusto que o `flutter run` do script antigo). Testado ao
vivo: login demo entra e a home carrega DADOS REAIS do backend local (21 matches,
campanhas). Assim o mobile roda local/rapido e o RESTAURAR-DEMO tambem vale.
⚠️ **RAM = so 7,7 GB**: emulador (~2-3,5 GB) + stack local + Chrome aperta;
recomendado rodar o emulador com POUCAS abas abertas.

## 🔴 BUG CRITICO achado no teste do emulador (17/08) — corrigido

O login no app instalado (release) dava **"Sem conexao. Verifique sua internet"**,
mesmo o emulador alcancando o backend por `nc 10.0.2.2:8080` (200). DUAS causas,
ambas afetando QUALQUER APK release — inclusive a do celular via Render, que
**teria falhado na feira**:
1. **Release NAO herda a permissao INTERNET** que o modo debug injeta (o
   `aapt2 dump permissions` da APK antiga NAO listava `android.permission.INTERNET`).
   Adicionada `<uses-permission android:name="android.permission.INTERNET"/>` no
   `android/app/src/main/AndroidManifest.xml`.
2. **Android release bloqueia cleartext (HTTP)** desde o Android 9. A APK do
   emulador usa `http://10.0.2.2` (nao-HTTPS). Criado
   `android/app/src/main/res/xml/network_security_config.xml` liberando cleartext
   APENAS para `10.0.2.2`/`localhost`/`127.0.0.1`, referenciado no manifest por
   `android:networkSecurityConfig`. Producao (Render, HTTPS) segue exigindo TLS.
As DUAS APKs foram refeitas. ⚠️ **Licao: sempre conferir
`aapt2 dump permissions` numa APK release ANTES de confiar que ela conecta** — o
`flutter run` (debug) engana porque tem INTERNET e cleartext liberados.

## ⚡ Emulador LENTO era o NAT do QEMU — trocado por adb reverse (17/08)

O usuario achou o app do emulador "muito lerdo" e suspeitou que fosse o Render.
NAO era: a APK tinha `10.0.2.2` embutido (conferido com `unzip`+`grep` no
`lib/x86_64/libapp.so`), 100% local. O gargalo era o **NAT user-mode do QEMU**:
medido de DENTRO do emulador, `10.0.2.2:8080` levava **600-900ms por chamada**
mesmo com o backend aquecido (host respondia em 32ms). Com **`adb reverse
tcp:8080 tcp:8080`** + a APK apontando para **`http://127.0.0.1:8080`**, a mesma
chamada caiu para **63-142ms (~10x)**. Entao:
- APK do emulador REconstruida com `--dart-define=API_BASE=http://127.0.0.1:8080`
  (conferido: 17x `127.0.0.1`, zero `onrender`/`10.0.2.2` no binario).
- `INICIAR-MOBILE-EMULADOR.bat` roda `adb reverse tcp:8080 tcp:8080` apos o boot,
  antes de instalar/abrir. adb reverse persiste enquanto a conexao adb viver;
  reboot do emulador exige rodar de novo (o bat ja faz).
- Como o app fala com o backend LOCAL, **o RESTAURAR-DEMO tambem reseta o que o
  emulador mostra** (mesmo banco); depois de restaurar, puxar a tela p/ atualizar
  ou reabrir o app.
⚠️ **RAM 7,7 GB e o limite real:** durante ESTA sessao o emulador caiu varias
vezes por pressao de memoria (backend + MySQL + daemons de build do Gradle +
emulador). Na feira, sem builds rodando, sobra mais folga; ainda assim rodar o
emulador com POUCAS abas de Chrome. `./gradlew --stop` libera ~1-2 GB apos builds.

## Pedidos futuros do usuario (registrados p/ retomar)
- **Janela de ~2 semanas (ate ~fim de agosto/inicio de setembro):** o usuario e o
  grupo vao TESTAR bastante e depois trazer mudancas. Nao mexer sozinho no que
  esta pronto; esperar o feedback deles.
- **Dicas de chave Groq:** mais para frente o usuario quer orientacao de como
  colocar a chave do Groq (onde gerar, colar em `chave-ia.txt`, ligar a IA de
  verdade nas 8 frentes). Ja existe o `chave-ia.txt.EXEMPLO` na pasta. Ver
  [[connect-ong-assistente-ia.md]] e a nota do modelo de visao abaixo.

## Detalhes que voltam a morder
- Rebuild do jar (`mvn package`) FALHA se o backend estiver rodando (Windows nao
  renomeia o jar aberto): PARAR o 8080 antes. Erro = "Unable to rename ... .jar".
- Heredoc do Git Bash e fragil aqui; para editar arquivo, usar Edit, nao
  `python - <<EOF`.
- A Area de Trabalho e no OneDrive (ver secao 1) — mover/criar coisas la exige
  PowerShell e `attrib +P` para nao virar nuvem-so.
