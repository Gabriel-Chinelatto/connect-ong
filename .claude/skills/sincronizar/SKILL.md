---
name: sincronizar
description: Sincroniza os 3 repositorios do Connect ONG (mobile, backend, desktop) com o GitHub - puxa do remoto e envia as mudancas locais. Use quando o usuario pedir "sincronizar", "sync", "atualizar do git", "subir tudo", ou quando ele trocar de computador (deste PC para o notebook da feira e vice-versa) e quiser deixar tudo em dia sem intervencao manual.
---

# Sincronizar Connect ONG

Objetivo: deixar os 3 repositorios iguais ao GitHub, nos dois PCs (usuarios do
Windows diferentes), sem o usuario mexer em nada. Puxa do remoto e envia o local.

## O que fazer

Para CADA um dos 3 repositorios, na ordem (mobile primeiro, pois carrega memoria/skill):

1. **mobile** — pasta que contem `.claude/memory` (ex.: `%USERPROFILE%\connect-ong`
   ou `%USERPROFILE%\Desktop\connect-ong`). Branch `main`.
2. **backend** — raiz git `connect-ong-api` (ex.: `%USERPROFILE%\IdeaProjects\connect-ong-api`).
   Branch `master`. (A raiz Maven fica mais funda, mas o `.git` esta em `connect-ong-api`.)
3. **desktop** — pasta `connect_ong - Desktop` ou `connect-ong-desktop`. Branch `main`.

Descubra o caminho real de cada repo testando os candidatos sob `%USERPROFILE%`
(o layout muda entre os PCs). So opere nos que existirem e tiverem `.git`.

Em cada repo, rode nesta ordem (o objetivo e SINCRONIZAR SEM REGRESSAO):

1. **Pull seguro** — `git pull --rebase --autostash` (traz o remoto guardando o
   local; nunca reverte trabalho). Se der conflito: `git rebase --abort` para
   restaurar o estado anterior, PARE nesse repo e avise o usuario. NUNCA use
   `--force`/`reset --hard`.
2. **Registrar local** — `git add -A`; se houver staged (`git diff --cached --quiet`
   retorna non-zero) faca `git commit` com mensagem curta em portugues.
3. **Verificar ANTES de enviar (impede regressao)** — so envie se a verificacao
   passar, para nao propagar um erro ao outro PC:
   - repo Flutter (tem `pubspec.yaml`): `flutter analyze` deve estar limpo.
   - backend (raiz `connect-ong-api`): compilar em
     `API - Chinelatto - att2\API - Chinelatto\API - Chinelatto` com
     `mvn -q -o -DskipTests compile` (ou `mvnw` neste PC) sem erro. Idealmente rode
     tambem `mvn -q test` (os testes sao a real barreira de regressao) quando der.
4. **Enviar** — se a verificacao passou E ha commits a frente do remoto
   (`git rev-list --count @{u}..HEAD` > 0): `git push`. Se a verificacao falhou,
   NAO empurre: deixe o commit local, e avise o usuario para corrigir e sincronizar
   de novo. Se nada a frente: "ja estava em dia".

Atalho pratico: existe o `sincronizar.bat` na raiz do repo mobile que faz exatamente
isso com um clique (pull seguro + verificacao + push). Voce pode rodar o mesmo fluxo
por comandos aqui no chat.

## Regras
- NUNCA use `--force`/`reset --hard`. Em conflito de merge/rebase, pare e reporte.
- Respeite as preferencias do projeto: mensagens de commit em portugues, sem
  co-autoria do Claude, mobile/desktop na `main` e backend na `master`.
- Ao final, reporte um resumo curto: para cada repo, o que foi puxado e o que foi
  enviado (ou "ja estava em dia").
