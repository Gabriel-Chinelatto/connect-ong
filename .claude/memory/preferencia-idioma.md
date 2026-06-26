---
name: preferencia-idioma
description: "Idioma de TODAS as comunicações e artefatos do Connect ONG = português (preferência do usuário)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: fd5869c2-ce42-4ab3-b411-545f30b4d907
---

O usuário pediu (2026-06-26) que **TODAS as informações deste trabalho estejam em português**, para facilitar o entendimento dele.

**Por quê:** o usuário entende melhor em português e quer poder ler/revisar qualquer artefato do projeto sem barreira de idioma.

**Como aplicar:**
- **Respostas ao usuário, resumos e explicações:** sempre em português.
- **Mensagens de commit:** português (já era a regra — ver [[git-workflow-preferences]]).
- **Comentários de código, documentação (README, ROTEIRO_DEMO, NORMALIZACAO etc.) e mensagens de UI:** português.
- **Anotações de memória novas:** preferir português quando não atrapalhar a clareza técnica (as antigas estão em inglês/misto; traduzir só se for pedido — não vale o risco de reescrever em massa).
- Lembrete técnico que permanece: **nunca usar emojis em strings salvas no banco** (MySQL 5.6 utf8); acentos em português são OK. Ver [[connect-ong-architecture]].
