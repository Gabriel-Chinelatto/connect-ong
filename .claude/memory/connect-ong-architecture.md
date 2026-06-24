---
name: connect-ong-architecture
description: "Connect ONG system layout — 3 repos (mobile, desktop, backend) and where each lives on disk"
metadata: 
  node_type: memory
  type: project
  originSessionId: fd5869c2-ce42-4ab3-b411-545f30b4d907
---

Connect ONG is a donation platform (academic TCC) with three separate repos under GitHub user `Gabriel-Chinelatto`:

- **Mobile** (most complete): `C:\Users\01gabriel.MAQCHINELATTO\connect-ong` — Flutter, repo `connect-ong`, branch `main`. Roles DOADOR/ONG, session persisted via shared_preferences.
- **Desktop** (early stage): `C:\Users\01gabriel.MAQCHINELATTO\connect_ong - Desktop` — Flutter + provider, repo `connect-ong-desktop`, branch `main`. Models around Empresa/ONG; `empresa_service.dart` empty. Diverged from mobile.
- **Backend**: `C:\Users\01gabriel.MAQCHINELATTO\IdeaProjects\connect-ong-api` (actual Maven root is deeply nested: `API - Chinelatto - att2/API - Chinelatto/API - Chinelatto`). Spring Boot 3.5.6 / Java 17, repo `connect-ong-api`, branch `master`.

**Platform requirement (from advisor site):** the project MUST have THREE distinct frontends — **Web, Desktop, and Mobile** — all consuming the central RESTful API. So we CANNOT merge them into one. **Decision (pending final user confirm):** differentiate by persona instead of cloning — **Mobile = doador-facing app**; **Desktop = ONG administrative panel** (manage needs/campaigns, accept matches, prestação de contas, chat, ONG dashboard); **Web = Flutter-web build of the doador app** (responsive, reuses the mobile codebase so "web" is largely free) OR a public institutional portal. This gives each platform a real purpose = the "alive/professional" feel judges want. See [[connect-ong-delivery-rules]].

Both Flutter apps hit the backend REST API at `http://localhost:8080`. Endpoints: `/usuarios` (+`/login`), `/doacoes` (CRUD), `/ongs` (CRUD, `?nome=` search), `/projetos`. Login uses BCrypt. Entities: Usuario, Doacao, Ong, Projeto.

**DB:** remote MySQL at `143.106.241.3:3306/cl203161` (already configured in application.properties; no local DB needed). Hibernate `ddl-auto=update`. ⚠️ **GOTCHA:** it's MySQL **5.6 with utf8 (3-byte) columns — emojis (4-byte) cause a 500 "Incorrect string value" on insert.** Never put emojis in strings that get SAVED to the DB (notification titles, etc.); accents (á, ç) are fine. Emojis are OK only in UI-only text (snackbars, labels). Proper fix later = migrate to utf8mb4.

**Security note:** DB credentials are committed in plaintext in application.properties on a public repo — flagged to user, not yet fixed. See [[git-workflow-preferences]].
