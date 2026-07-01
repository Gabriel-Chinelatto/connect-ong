# Memory Index

- [Connect ONG architecture](connect-ong-architecture.md) — 3 repos + 3-platform rule (mobile=doador, desktop=ONG admin, web), API, remote MySQL
- [Connect ONG roadmap](connect-ong-roadmap.md) — MASTER roadmap; **0-20 e 22-30 DONE** (todas as funções: Match→…→Mural/Ranking/Conquistas/Favoritos/Denúncia/PDF); **resta só o Bloco 21 (polimento visual MASTER FINISH)** por decisão do usuário + recapitular deferred; compress-near-deadline rule
- [Connect ONG deferred](connect-ong-deferred.md) — BACKLOG de itens adiados nos blocos (JWT enforcement, utf8mb4, signup doador mobile, validar Docker, hospedar web…); recapitular após Bloco 30
- [Connect ONG remodel mobile](connect-ong-remodel-mobile.md) — **Bloco 21 EM ANDAMENTO**: plano de remodelação visual do mobile (design system + bottom nav 5 abas, ref iFood/Instagram, minhas-doações é bug de dados, foto galeria); decisões: manter verde+elevar, IA por último, emulador (SDK ausente)
- [Connect ONG profile & settings](connect-ong-profile-settings.md) — spec for Bloco 8: profile + settings center (appearance/notif/privacy/security/accessibility)
- [Connect ONG vision](connect-ong-vision.md) — product vision, "treat as real product", DOADOR/ONG roles
- [Connect ONG milestones](connect-ong-milestones.md) — FECITEC Aug 31-Sep 2, Nov final, July break, MVP-checkpoint-alert rule
- [Connect ONG banca feedback](connect-ong-banca-feedback.md) — board wants interaction; hero feature = match + chat (tip, not win guarantee)
- [Connect ONG delivery rules](connect-ong-delivery-rules.md) — advisor-site rules: GitHub commits per member, RESTful, 3 frontends, A0 poster + MVP
- [Connect ONG tech guidelines](connect-ong-tech-guidelines.md) — mandatory backend/frontend/DB standards, fixed stack
- [Git workflow preferences](git-workflow-preferences.md) — **auto-commit + auto-push** em cada checkpoint útil (restore point), sem pedir; no Claude co-authorship; mobile/desktop=main, backend=master
- [Preferência de idioma](preferencia-idioma.md) — **TODAS as comunicações e artefatos do projeto em PORTUGUÊS** (respostas, commits, comentários, docs, UI)
- [Permissões do projeto](permissoes-projeto.md) — usuário NÃO quer prompts de permissão neste projeto; settings.local.json com defaultMode=bypassPermissions
- [Preferência de gráficos](preferencia-graficos.md) — usar SVG (flutter_svg) / imagens free para itens visuais; autorar SVGs originais nas cores da marca
- [Notebook FECITEC](connect-ong-notebook-fecitec.md) — **2ª máquina (user `gabri`) que vai p/ a FECITEC**: caminhos dos 3 repos, JDK Corretto 21, Maven fixo, Android SDK, scripts em INICIAR-FECITEC; **RISCO = depende do MySQL remoto da escola** (testar login no evento)
- [Ambiente Java + Avast TLS](ambiente-java-avast-tls.md) — gotcha do notebook: **Avast intercepta HTTPS** → ferramentas Java (sdkmanager/Gradle/Maven novo) dão PKIX; fix = importar a CA "Avast Web/Mail Shield Root" no cacerts do Corretto 21
