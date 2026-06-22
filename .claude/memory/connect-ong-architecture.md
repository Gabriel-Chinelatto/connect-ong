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

Both Flutter apps hit the backend REST API at `http://localhost:8080`. Endpoints: `/usuarios` (+`/login`), `/doacoes` (CRUD), `/ongs` (CRUD, `?nome=` search), `/projetos`. Login uses BCrypt. Entities: Usuario, Doacao, Ong, Projeto.

**DB:** remote MySQL at `143.106.241.3:3306/cl203161` (already configured in application.properties; no local DB needed). Hibernate `ddl-auto=update`.

**Security note:** DB credentials are committed in plaintext in application.properties on a public repo — flagged to user, not yet fixed. See [[git-workflow-preferences]].
