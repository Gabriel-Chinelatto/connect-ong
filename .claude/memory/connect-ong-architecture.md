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

Both Flutter apps hit the backend REST API at `http://localhost:8080` (Swagger em `/swagger-ui.html`). Login uses BCrypt + JWT (enforcement OFF — ver [[connect-ong-deferred]]). **Entities (atuais):** Usuario, Ong, Necessidade, Interesse, Mensagem, Prestacao, Avaliacao, Notificacao, Preferencia, DoacaoFinanceira, AuditLog, **Campanha** (era Projeto — renomeada via Liquibase no Bloco 22), **Atividade** (feed global da Timeline, Bloco 23), + legado Doacao. **Endpoints principais:** `/usuarios`(+`/login`), `/auth`(`/me`,`/refresh`), `/ongs`, `/necessidades`, `/interesses`, `/mensagens`, `/prestacoes`, `/avaliacoes`, `/notificacoes`, `/doacoes-financeiras`, `/campanhas`(+`/destaques`,`/{id}/contribuir`,`/{id}/encerrar`), `/atividades`(feed global; filtra ongId; limit), `/ongs/{id}/perfil-publico`(agrega ong+necessidades+campanhas+avaliacoes+prestacoes — Bloco 24), `/audit-logs`, `/publico/estatisticas`, `/demo/seed`.

**Status:** blocos **0-30 concluídos** (commitados E **pushados**; regra = auto-commit+push, ver [[git-workflow-preferences]]). **Resta só o Bloco 21 (polimento visual MASTER FINISH)** — deixado p/ o fim por decisão do usuário — + recapitular [[connect-ong-deferred]]. Entidades NOVAS (blocos 28-29): **Favorito**, **Denuncia** (+ Atividade no 23). Endpoints novos: /atividades, /ongs/{id}/perfil-publico, /ongs/{id}/transparencia, /publico/ranking, /conquistas/(doador|ong)/{id}, /favoritos(+/ids), /denuncias. **GOTCHA de dev:** ao adicionar @RestController/@Entity novo, o hot-reload do DevTools trava (404 persistente / context quebrado) — SEMPRE reiniciar a API limpa (matar o java real da 8080 via `netstat -ano|grep :8080|grep LISTENING` → taskkill //F; confirmar 8080 livre 2x antes de subir, pois sobram wrappers maven órfãos das tentativas). Bloco 21 (polimento visual) ficou para o final. Modo Feira: senha demo padrão `demo123`, conta ONG `demo.larviva@connectong.com`, doador `demo.joao@connectong.com`.

**DB:** remote MySQL **5.6.44** at `143.106.241.3:3306/cl203161` (it's the user's OWN isolated schema on the shared school server; password in gitignored application-local.properties). **Schema is now versioned by Liquibase** (`src/main/resources/db/changelog/db.changelog-master.yaml`), Hibernate `ddl-auto=validate` (no longer `update` — Hibernate doesn't touch the DB anymore). NOTE: **Flyway Community can't do MySQL 5.6** (gated to paid Teams Edition in all versions tested); Liquibase is free and works. ⚠️ **GOTCHA:** it's MySQL **5.6 with utf8 (3-byte) columns — emojis (4-byte) cause a 500 "Incorrect string value" on insert.** Never put emojis in strings that get SAVED to the DB (notification titles, etc.); accents (á, ç) are fine. Emojis are OK only in UI-only text (snackbars, labels). Proper fix later = migrate to utf8mb4.

**Security note:** DB credentials are committed in plaintext in application.properties on a public repo — flagged to user, not yet fixed. See [[git-workflow-preferences]].
