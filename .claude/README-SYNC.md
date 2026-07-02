# Sincronizar Claude Code entre os dois PCs (este e o notebook da feira)

Objetivo: baixar do git num PC, trabalhar, dar push, e continuar no outro PC —
sem nada ficar preso a uma maquina so. Usuarios do Windows diferentes (ex.:
`01gabriel.MAQCHINELATTO` aqui, `gabri` no notebook) nao atrapalham.

## O que JA sincroniza pelo git (nada a fazer)
Tudo isto mora dentro do repo **mobile** (`connect-ong/.claude/`) e e versionado,
entao vem junto no `git clone`/`git pull`:

- **`memory/`** — a memoria do projeto (fatos, decisoes, preferencias). E o
  "cerebro" que o Claude carrega a cada sessao. Ja esta toda no git.
- **`settings.json`** — preferencias compartilhadas (lista de permissoes, sem
  co-autoria nos commits). Deixado **portavel**: sem caminho absoluto de maquina.
- **`skills/fable5/`** — a skill de trabalho autonomo. Antes so existia no diretorio
  do usuario deste PC (`~/.claude/skills`), por isso NAO ia para o notebook. Agora
  esta dentro do projeto e viaja junto. (A copia no `~/.claude/skills` deste PC pode
  ficar; a do projeto e a fonte de verdade — edite sempre a do projeto.)

## O que cada maquina configura UMA VEZ (nao vai para o git)
- **`settings.local.json`** — coisas especificas da maquina: o modo de permissao e
  os caminhos absolutos dos **outros dois repos** (backend e desktop), que mudam
  conforme o usuario do Windows. Esse arquivo esta no `.gitignore` de proposito
  (cada PC tem o seu).
  - **AUTOMATICO:** basta rodar o `sincronizar.bat` (duplo-clique). Na primeira vez
    numa maquina, se o `settings.local.json` nao existir, ele **cria sozinho** a
    partir do modelo, ja preenchido com os caminhos reais dos repos daquela maquina
    (descobre backend e desktop). Depois disso, **reabra o Claude Code** no repo
    mobile para ele carregar a config. So gera se nao existir — nunca sobrescreve o seu.
  - Manual (opcional): copie `settings.local.json.example` para `settings.local.json`
    e troque `SEU_USUARIO` pelo usuario do Windows daquela maquina.

## Fluxo de trabalho nos dois PCs
1. Em cada maquina, clone os 3 repos:
   - mobile: `connect-ong` (este; traz a memoria + settings + skill)
   - backend: `connect-ong-api`
   - desktop: `connect-ong-desktop` (pasta local "connect_ong - Desktop")
2. Abra o Claude Code **a partir do repo mobile** (`connect-ong`) como diretorio
   principal — e o que ancora a memoria e a skill. Os outros dois entram como
   `additionalDirectories` (no seu `settings.local.json`).
3. Crie o `settings.local.json` da maquina (passo acima).
4. Trabalhe normal. A cada checkpoint util, os commits (auto-commit + push) levam
   memoria, settings e skill para o git; no outro PC, um `git pull` traz tudo.

Obs.: a memoria fica ancorada ao repo **mobile**. Sempre inicie a sessao por ele
(com os outros dois como diretorios adicionais), e a memoria estara la nas duas
maquinas.
