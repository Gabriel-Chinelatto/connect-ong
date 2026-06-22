---
name: git-workflow-preferences
description: How the user wants git commits and GitHub sync handled for the Connect ONG projects
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fd5869c2-ce42-4ab3-b411-545f30b4d907
---

The user wants git handled conservatively: **commit/push only when explicitly asked** — never commit or push on my own initiative. Commit messages must have **no Claude co-authorship** (configured via `includeCoAuthoredBy: false` and empty `attribution` in settings.local.json).

**Why:** This is a TCC (academic project) the user owns; they want full control over what lands on their public GitHub and clean commit history under their name only.

**How to apply:** After finishing work, leave changes staged/uncommitted unless the user says "commit", "push", or "sincroniza". GitHub auth works via Git Credential Manager — no `gh` CLI installed. See [[connect-ong-architecture]].
