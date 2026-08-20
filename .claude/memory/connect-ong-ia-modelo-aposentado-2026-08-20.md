---
name: connect-ong-ia-modelo-aposentado-2026-08-20
description: A IA do projeto ficou dias morta em silencio porque a Groq aposentou o modelo llama-3.1-8b-instant (404 em toda chamada); a correcao foi cadeia de modelos + log + dieta de tokens, e o "HTTP ERROR 501" do site era outro programa na porta 8090
metadata:
  type: project
---

# A IA "muito limitada" era a IA MORTA (2026-08-20)

O usuário mostrou 3 telas do computador da apresentação: o chat "Sobre o
Desenvolvimento" recusando a palavra **"matches"** como fora de escopo, a Dora
respondendo com o selo **"Modo básico"**, e o site local em `127.0.0.1:8090`
com **HTTP ERROR 501**. Diagnóstico: eram três causas independentes.

## 1. A Groq aposentou o modelo — e ninguém ficou sabendo

`llama-3.1-8b-instant` **não existe mais** (404 `model_not_found` em TODA
chamada, confirmado ao vivo com a chave real). Como o `GroqService` engolia
qualquer erro e devolvia `Optional.empty()`, os **seis** recursos de IA caíam
no fallback por regras. A chave estava válida o tempo todo.

**O que escondeu o problema:** a IA foi desenhada para nunca falhar na tela —
ela degrada para regras e deixa só um selo discreto "Modo básico". Sem nenhum
log, ninguém percebe. **Lição: fallback silencioso precisa de log e de um jeito
de olhar de fora.**

### O que ficou no lugar (commit `83d3ce4`, backend)

- **Modelo:** `openai/gpt-oss-120b` (~1,0s, PT-BR bom, 131k de contexto).
- **Cadeia de reserva** `app.ia.groq.modelos-reserva` = `gpt-oss-20b,qwen3.6-27b`:
  se o principal devolve **erro HTTP**, tenta o próximo. Resolve duas coisas —
  modelo aposentado não derruba mais nada, e o **limite gratuito é de 8.000
  tokens por MINUTO POR MODELO** (cada modelo tem seu próprio balde), então a
  fila do estande aguenta ~3x mais perguntas.
  ⚠️ Falha de **rede/timeout** NÃO tenta o próximo (só somaria 15s de espera).
- **Log** (`log.warn`) em toda resposta não-2xx, com status/modelo/motivo, nunca
  a chave.
- **`GET /ia/status[?ping=true]`** (público, sem segredo): diz se a chave existe
  **naquele ambiente**, os modelos e o `ultimoErro`. É como conferir o Render
  pelo celular antes de apresentar. Está no `COMO-MOSTRAR.md`.

### Pegadinhas medidas (todas ao vivo, com a chave real)

| Coisa | O que se aprendeu |
|---|---|
| `reasoning_effort` | Valor **diferente por família**: `none` no Qwen3, **`low`** no gpt-oss (`none` dá 400). Quem não reconhece o parâmetro dá 400 — só mandar para quem aceita. |
| Teto de tokens baixo | Os modelos atuais "pensam": `max_tokens=5` devolve **texto vazio** com a IA perfeita. O ping usa 64. |
| Visão (foto do doador) | `qwen/qwen3.6-27b` é o **único** do free tier que aceita imagem (os gpt-oss respondem `400 content must be a string`), mas devolve **503 "over capacity" em ~2 de 3 chamadas**. Por isso: 3 tentativas e, se não der, responder **sem a foto** pelo caminho de texto. |
| `<think>` | O Qwen deixa o bloco de raciocínio vazar no texto; o `GroqService` agora o remove. |

## 2. "matches" recusado como fora de escopo

O fallback por regras casava **literal**: `"matches"` não contém `"match"`,
a seção "Como funciona o MATCH" tirava zero e caía na recusa educada — logo o
coração do produto. Agora cada termo também é testado no **singular**.

E o prompt levava o **documento inteiro** (18 KB ≈ 5.000 tokens) em cada
pergunta: com 8.000 tokens/minuto, a **segunda pergunta seguida já estourava**.
Agora vão o **índice dos assuntos** (para a IA saber o que existe e não chamar
de fora de escopo) + os **trechos relevantes** (~1.500 tokens). Verificado:
4 perguntas seguidas, todas em `modo:"ia"`.

## 3. O HTTP ERROR 501 do site (porta 8090)

**No Windows, `SO_REUSEADDR` deixa ligar numa porta que OUTRO processo já está
usando — sem erro nenhum.** O `serve.py` imprimia "Connect ONG em
http://localhost:8090" como se estivesse tudo certo, mas quem respondia o
navegador era o outro programa (típico: um `dartvm` sobrando de um
`flutter run`). Confirmado com um teste de 10 linhas: dois sockets ligam na
mesma porta e o segundo nem reclama.

Corrigido no repo do site (`connect-ong-web`): `allow_reuse_address` só fora do
Windows + checagem da porta antes de subir, recusando com o comando pronto para
achar e matar quem está ocupando.

## Como conferir tudo isso rapidinho

```bash
# a IA está viva? (funciona no Render e no local)
curl "https://connect-ong-api.onrender.com/ia/status?ping=true"
# "ping":"ok" -> pode apresentar
# "chaveConfigurada":false -> falta APP_IA_GROQ_KEY naquele ambiente
# ultimoErro com 404 -> o modelo foi aposentado de novo: ver os disponíveis em
#   curl https://api.groq.com/openai/v1/models -H "Authorization: Bearer $CHAVE"
```

A chave local está em `src/main/resources/application-local.properties`
(gitignored). Testes do backend: **189** (6 novos em `AssistenteDevIaTest`).

Ver também [[connect-ong-assistente-ia]], [[connect-ong-frete-e-ia-2026-07-10]]
e [[connect-ong-ajustes-pos-recheio-2026-08-12]].
