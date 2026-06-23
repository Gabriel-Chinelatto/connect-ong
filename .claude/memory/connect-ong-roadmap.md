---
name: connect-ong-roadmap
description: The agreed MVP roadmap blocks for Connect ONG and which are done/in-progress
metadata:
  type: project
---

Lean-but-professional MVP roadmap toward FECITEC (see [[connect-ong-milestones]]). Blocks in dependency order:

- **Bloco 0 — Fundação:** ✅ DONE (backend). Security (DB creds externalized), Swagger + endpoint docs, global exception handling, output DTOs (already existed). Backend commits on `connect-ong-api` master: e8b8d68, 71ba214, 0b5d0e1. **Desktop repurposing + DOADOR/ONG standardization were MOVED to Bloco 2** (avoid building a throwaway skeleton).
- **Bloco 1 — Match (backend):** ✅ DONE. Domain: **Necessidade** (need published by an ONG) + **Interesse** (doador's interest; status PENDENTE/ACEITO/RECUSADO — ACEITO = a "match"). Full layers (model/repo/service/DTO/controller) per [[connect-ong-tech-guidelines]]. Endpoints: `POST/GET /necessidades` (filter ?ongId/?status), `POST/GET /interesses` (filter ?doadorId/?ongId), `PUT /interesses/{id}/aceitar|recusar`. Prevents duplicate interest. Tested end-to-end via curl (publish → interest → accept → visible to both sides). Commits on master: 5ad841e, d472646. Tables `necessidade`+`interesse` auto-created.
- **Bloco 2 — Match (telas) + Desktop:** mobile (doador) feed + interesse + meus matches; desktop repurposed as the **ONG admin panel** (publish needs, see interested doadores, accept/reject). Standardize DOADOR/ONG here.
- **Bloco 3 — Chat em tempo real:** Spring WebSocket; chat opens on an accepted Interesse.
- **Bloco 4 — Dashboard de impacto + polimento:** ⚠️ ALERT THE USER when this is reached (pré-FECITEC) so they give remaining time + availability for a re-plan.
- **Bloco 5 — Web (Flutter web build) + pôster + ensaio do demo.** (A0 poster already done.)

Cadence ([[git-workflow-preferences]]): I self-verify each step technically; user usage-tests at end of each block; commit at block end + safe mid-block points; announce each block completion.
