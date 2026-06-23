---
name: connect-ong-roadmap
description: The agreed MVP roadmap blocks for Connect ONG and which are done/in-progress
metadata:
  type: project
---

**RECURRING RE-PLAN RULE (user-set 2026-06-23, standing):** every time we reach the **last or second-to-last block of the currently-planned set**, I must proactively **ask the user how much time remains** before FECITEC, then extend/guide the next blocks toward the **FULL professional vision** — all features the user requested at the start, made as professional as possible (it just needs time). Keep repeating this loop near the end of each planned set **until the user says we are close to the presentation**. Do not silently stop at the end of a planned set — always re-plan forward.

Lean-but-professional MVP roadmap toward FECITEC (see [[connect-ong-milestones]]). Blocks in dependency order:

- **Bloco 0 — Fundação:** ✅ DONE (backend). Security (DB creds externalized), Swagger + endpoint docs, global exception handling, output DTOs (already existed). Backend commits on `connect-ong-api` master: e8b8d68, 71ba214, 0b5d0e1. **Desktop repurposing + DOADOR/ONG standardization were MOVED to Bloco 2** (avoid building a throwaway skeleton).
- **Bloco 1 — Match (backend):** ✅ DONE. Domain: **Necessidade** (need published by an ONG) + **Interesse** (doador's interest; status PENDENTE/ACEITO/RECUSADO — ACEITO = a "match"). Full layers (model/repo/service/DTO/controller) per [[connect-ong-tech-guidelines]]. Endpoints: `POST/GET /necessidades` (filter ?ongId/?status), `POST/GET /interesses` (filter ?doadorId/?ongId), `PUT /interesses/{id}/aceitar|recusar`. Prevents duplicate interest. Tested end-to-end via curl (publish → interest → accept → visible to both sides). Commits on master: 5ad841e, d472646. Tables `necessidade`+`interesse` auto-created.
- **Bloco 2 — Match (telas) + Desktop:** ✅ DONE. Mobile (doador): feed de necessidades + "tenho interesse" + meus matches (commit f42d77c on connect-ong main). Desktop repurposed as **ONG admin panel** — PainelOngScreen resolves the ONG by login email (selector fallback), tabs Necessidades + Interesses (aceitar/recusar), publish-necessidade form; login now routes to the ONG panel instead of empresa screens (commits b7dd8c0, b30695b on connect-ong-desktop main). Notes/TODO: (1) native Windows build needs **Developer Mode** enabled (symlinks) — runs on Chrome without it; (2) old `screens/empresa/*` files are now dead code (clean up later); (3) no real link between ONG login account and Ong profile — bridged by email-match for the demo, proper linking is future work; (4) visual polish of the Match screens deferred to Bloco 4.
- **Bloco 3 — Chat:** ✅ DONE (via polling, per user choice — WebSocket is a later upgrade if time allows). Backend: `Mensagem` entity tied to an Interesse, `MensagemService`/Controller with `GET/POST /mensagens?interesseId=`, rule "chat only on ACEITO match" (commit 3859154 on api master). Frontends: ChatScreen (mobile, remetente DOADOR — opened from an accepted match in Meus Matches) and ChatOngScreen (desktop, remetente ONG — "Conversar" button on accepted interests). Both poll every 2s, bubble UI aligned by sender. Commits: mobile 3b46290, desktop 0596097. Tested end-to-end (both sides send/receive, history ordered, pending-match blocked).
**POST-MVP calibrated plan (set 2026-06-23, balanced, front-loaded into July):**
- **Bloco 4 — Dashboard de impacto:** 🔜 NEXT. Doador: nº de matches, ONGs apoiadas, interesses; ONG: necessidades publicadas, interessados, matches fechados. Tells the visual "story" for judges.
- **Bloco 5 — Profissionalização & limpeza:** resolve the ~50 lints (withOpacity→withValues, remove debug prints, BuildContext-across-async-gaps), delete dead `screens/empresa/*`, finalize DOADOR/ONG standardization, and ONG self-registration that creates a linked login+profile (fixes the email-bridge gap).
- **Bloco 6 — Tempo real + confiança:** upgrade chat to WebSocket (true real-time) + ONG verification seal (selo).
- **Bloco 7 — Web + dados de demonstração:** Flutter web build published + seed realistic ONGs/necessidades for the demo.
- **Bloco 8 (August — final touches):** final visual polish, A0 poster review, demo rehearsal/script, final testing.

Plan is flexible; reprioritize as we go. Cadence ([[git-workflow-preferences]]): I self-verify each step technically; user usage-tests at end of each block; commit at block end + safe mid-block points; announce each block completion.
