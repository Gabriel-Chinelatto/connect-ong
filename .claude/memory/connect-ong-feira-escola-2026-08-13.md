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

## 1. Pasta unica `C:\Users\gabri\Desktop\FEIRA ESCOLA\`

Tudo o que estava solto na Area de Trabalho foi consolidado nela (os .bat antigos
soltos foram apagados; `INICIAR-FECITEC` ganhou um `_SUPERADO-LEIA.txt`). Conteudo:
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

## Detalhes que voltam a morder
- Rebuild do jar (`mvn package`) FALHA se o backend estiver rodando (Windows nao
  renomeia o jar aberto): PARAR o 8080 antes. Erro = "Unable to rename ... .jar".
- Heredoc do Git Bash e fragil aqui; para editar arquivo, usar Edit, nao
  `python - <<EOF`.
