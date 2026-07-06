---
name: git-workflow-preferences
description: How the user wants git commits and GitHub sync handled for the Connect ONG projects
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fd5869c2-ce42-4ab3-b411-545f30b4d907
---

Commit + testing cadence (updated 2026-06-22, refined): work is organized in roadmap BLOCKS. The agreed rhythm:
- **I self-verify EVERY step technically** (does it compile? `flutter analyze` clean? endpoint responds via Swagger/curl?) — this costs the user no time and keeps safety even though we batch user testing.
- **The user does manual/usage testing at the END of each block** (not every step) — saves their time.
- For **visual blocks** (UI: roadmap blocks 2, 3, 4), I may send a quick screenshot/short checkpoint mid-block to confirm direction — not a full test.
- **Commit AND push autonomously (no need to ask) whenever I judge it useful for an eventual restore point** — updated 2026-06-26: the user explicitly asked me to **auto-commit + auto-push at every checkpoint I deem necessary for recovery**, NOT only at block end. So: push after each block, and also at safe mid-block milestones (a working backend change, a passing frontend slice, a finished migration, etc.). Push all 3 repos as relevant. Permissions already allow git+PowerShell without prompts. Still announce briefly what was committed/pushed. Keep messages plain Portuguese, **no Claude co-authorship** (`includeCoAuthoredBy: false` + empty `attribution`). Branches: mobile/desktop=`main`, backend=`master`.

**Autonomia entre fases (reforçado 2026-07-06):** em trabalhos de múltiplas ondas/fases (orquestrações com subagentes), **NÃO parar entre as ondas para pedir autorização** — emendar uma fase na outra automaticamente, commitando+pushando a cada checkpoint, e só reportar ao usuário no fim (ou se algo bloquear de verdade, ex. limite de sessão). O usuário quer acompanhar pelo relatório final, não aprovar etapa por etapa.

**Progress signalling the user asked for:** announce when **each roadmap block** finishes (so they can track), and explicitly alert when reaching **Bloco 4 (pré-FECITEC)** so they can tell me remaining time + availability for a re-plan. The **A0 poster/banner is already done** — do not change it unless asked.

**Why:** This is a team TCC the user owns; they want clean history under their name (no AI attribution) but now trust me fully to handle commit+push cadence so they aren't clicking approvals constantly AND so there's always a remote restore point if something breaks.

**How to apply:** Work in small checkpointed steps; commit + push (to GitHub) at each meaningful checkpoint without asking; at session end, commit+push any remaining work. GitHub auth works via Git Credential Manager — no `gh` CLI installed. Reminder ([[connect-ong-delivery-rules]]): evaluation counts commits per member, so the other 3 teammates also need their own commit history. See [[connect-ong-architecture]].
