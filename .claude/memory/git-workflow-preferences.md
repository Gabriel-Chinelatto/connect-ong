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
- **Commit autonomously (no need to ask) at the end of each block + at safe points mid-block when I judge it useful.** Announce before committing. Keep commit frequency healthy — the evaluation counts commits per member ([[connect-ong-delivery-rules]]), so don't go too sparse. Commit messages: plain Portuguese, easy to read, **no Claude co-authorship** (`includeCoAuthoredBy: false` + empty `attribution`).

**Progress signalling the user asked for:** announce when **each roadmap block** finishes (so they can track), and explicitly alert when reaching **Bloco 4 (pré-FECITEC)** so they can tell me remaining time + availability for a re-plan. The **A0 poster/banner is already done** — do not change it unless asked.

**Why:** This is a team TCC the user owns; they want clean history under their name (no AI attribution) but now trust me to handle the commit cadence so they aren't clicking approvals constantly.

**How to apply:** Work in small checkpointed steps; at session end, tell the user it's wrapping up and commit. GitHub auth works via Git Credential Manager — no `gh` CLI installed. Reminder ([[connect-ong-delivery-rules]]): evaluation counts commits per member, so the other 3 teammates also need their own commit history. See [[connect-ong-architecture]].
