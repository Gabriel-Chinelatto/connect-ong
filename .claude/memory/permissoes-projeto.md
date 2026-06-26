---
name: permissoes-projeto
description: Preferência do usuário sobre prompts de permissão no projeto Connect ONG (liberar tudo)
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c6d1da92-9e74-4fa5-be2c-464ffcc31096
---

O usuário NÃO quer prompts de permissão neste projeto (pediu várias vezes, incl. comandos `curl` e comandos compostos/encadeados com `;` `|` `&&`).

**Why:** é o projeto acadêmico dele, na própria máquina; os prompts "Allow this bash command?" atrapalham o fluxo. O Claude Code não auto-aprova comandos compostos só por regras de prefixo (segurança), então a allow-list por si só não basta.

**How to apply:** configurado em `.claude/settings.local.json` (pessoal, fora do git) com `permissions.defaultMode: "bypassPermissions"` + `skipDangerousModePermissionPrompt: true` + `Bash`/`Bash(curl:*)` na allow. Se o usuário pedir para "desligar", trocar `defaultMode` para `"default"`. Relacionado: [[git-workflow-preferences]] (auto-commit+push sem pedir).
