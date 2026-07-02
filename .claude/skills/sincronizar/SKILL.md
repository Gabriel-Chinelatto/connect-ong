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

Em cada repo, rode nesta ordem:
- `git pull --rebase --autostash` (traz o remoto guardando o local; se der conflito,
  PARE nesse repo, avise o usuario e nao force).
- `git add -A`
- Se houver algo staged (`git diff --cached --quiet` retorna non-zero): `git commit`
  com uma mensagem curta em portugues descrevendo o que mudou (ou "sync" se nada
  obvio) e `git push`. Se nao houver, so informe "nada novo".

Atalho pratico: existe o `sincronizar.bat` na raiz do repo mobile que faz exatamente
isso com um clique; voce pode rodar o mesmo fluxo por comandos aqui no chat.

## Regras
- NUNCA use `--force`/`reset --hard`. Em conflito de merge/rebase, pare e reporte.
- Respeite as preferencias do projeto: mensagens de commit em portugues, sem
  co-autoria do Claude, mobile/desktop na `main` e backend na `master`.
- Ao final, reporte um resumo curto: para cada repo, o que foi puxado e o que foi
  enviado (ou "ja estava em dia").
