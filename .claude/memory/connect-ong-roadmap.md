---
name: connect-ong-roadmap
description: Full MASTER roadmap for Connect ONG to a professional finish — done blocks + all planned blocks with priority tiers
metadata:
  type: project
---

**PLANNING MODEL (user-set 2026-06-23):** keep ONE full master roadmap from start to "master finish", covering ALL originally-requested features (PDF + the user's GPT roadmap) + improvements I judge worthwhile, reflecting route changes (**desktop = ONG admin only, mobile = doador only, web = public/doador portal**). Work block by block. **As the presentation nears:** when the user says time is short, I COMPRESS the remaining blocks into ~2-3 to finish mobile+desktop cleanly. If all blocks finish WITH time left, the user says how much and I propose improvements. Keep until the user says we're close to the presentation. (Supersedes the earlier rolling re-plan rule.)

Priority tiers: **[CORE]** = needed for a strong professional demo; **[PLUS]** = valuable depth; **[STRETCH]** = nice-to-have, first to be cut/merged when time is short.

== DONE (Blocos 0-4, session 2026-06-22/23) ==
- 0 Fundação: DB creds externalized, Swagger, global exception handler, output DTOs.
- 1 Match backend: Necessidade + Interesse, full REST, accept/reject, no-duplicate rule.
- 2 Match telas: mobile doador (feed / tenho interesse / meus matches) + desktop ONG panel (publish, see interested, accept/reject).
- 3 Chat: Mensagem backend + polling chat UI both sides (remetente DOADOR/ONG), only on ACEITO match.
- 4 Dashboard de impacto: doador "Meu Impacto" stats + ONG panel stats header.

== PLANNED (forward) ==
**PHASE B — Profissionalização (July)**
- 5 [CORE] Limpeza & padronização: ✅ DONE. Mobile 55→0 lints (withOpacity→withValues x12 files, removed debug prints, mounted-guards, initialValue/activeThumbColor/scaleByDouble/super.key); desktop 4→0, deleted dead screens/empresa/* + empresa_service + cadastro_tipo, removed the "Empresa" concept (registration → CadastroOngScreen). Commits: mobile 5dc7187, desktop 82e4b66.
- 6 [CORE] ONG self-registration + account↔ONG link + finish persona split: ✅ DONE. Backend: Usuario.ongId column; POST /ongs/registro creates linked Ong profile + Usuario(tipo ONG, ongId) with BCrypt; login/cadastro return ongId (commit c0c7b07 on api master). Desktop: real ONG registration form (POST /ongs/registro), auth_service returns user map, login passes ongId/nome → PainelOngScreen uses ongId directly (email-match/selector now fallback only) (commit 3e3b525). Mobile = doador-only: removed Doador/ONG toggle (login always DOADOR → HomeDoadorScreen), deleted dead lib/receptor/*, root lib/login_page.dart, pedido.dart, pedido_card, tipo_usuario (commit 1ede197). Both apps + backend: zero lints, tested (register→login→ongId verified via curl).
- 7 [CORE] Design system & UX: ✅ DONE (foundation). Created `AppColors` palette in BOTH apps (single source, same brand green 0xFF0A8449); themes reference it; unified the divergent greens (mobile login was 0xFF2F8F46, desktop was 0xFF2E7D32 → both now 0xFF0A8449); applied Poppins typography on mobile too (matches desktop). Reusable components / responsiveness / feedback states already largely present. Deeper per-screen visual polish stays in Bloco 21. Commits: mobile 92e8015, desktop 87af12f.

- 8 [CORE] **Perfil & Central de Configurações** (user-requested; spec in [[connect-ong-profile-settings]]): ✅ DONE. Backend: Usuario profile fields (telefone/cidade/estado/bio/fotoUrl) + Preferencia entity (one/user, defaults) + PerfilController (GET/PUT perfil, PUT senha, GET/PUT preferencias) (api commit 24633c6). BOTH apps: ConfigController (ChangeNotifier) → MaterialApp via ListenableBuilder applies theme claro/escuro/auto + font size (textScaler) + dyslexia font (Lexend) + high contrast LIVE; loads prefs after login, clears on logout. Configurações screen (Aparência live + Notificações + Privacidade + Segurança/alterar senha) + Perfil screen (edit dados + avatar + stats). Mobile commits 7a50c6b, e29a0d4; desktop a2e4726. NOTE: "sessões ativas" still waits for JWT (Bloco 15); notification DELIVERY waits for Bloco 12 (prefs stored now). Full dark-mode coverage of every hardcoded-color screen is polish (Bloco 21).

**PHASE C — Confiança & Transparência (July)**
- 9 [PLUS] Verificação de ONG: ✅ DONE. Ong.verificada + cnpj; `PUT /ongs/{id}/verificar` (admin marks verified — no admin UI/auth yet, call via Swagger); OngResponseDTO + NecessidadeResponseDTO expose verified status. Mobile shows blue ✓ seal in the feed + "ONG Verificada" in ONG search; desktop registration collects CNPJ. Commits: api 6d0e083, mobile 4c9d95a, desktop 3da549b. (A proper admin approval screen could come later.)
- 10 [PLUS] Prestação de contas: ✅ DONE. Prestacao entity tied to an accepted Interesse (titulo, descricao, fotoUrl); `GET/POST /prestacoes?interesseId=`, rule "only on ACEITO match" (api commit d01e4a4). Desktop: "Prestar contas" button + dialog on accepted interests (mobile aabf5e7... wait that's mobile). Desktop commit d618f63. Mobile: doador sees "Prestação de contas" button on accepted matches → screen with relato + photo (commit aabf5e7). Tested end-to-end + pending-match guard.
- 11 [PLUS] Avaliações: ✅ DONE. Avaliacao entity (nota 1-5 + comentario, one per doador/ONG = upsert); `GET/POST /avaliacoes?ongId=`; recomputes Ong.notaMedia + totalAvaliacoes (denormalized, exposed in OngResponseDTO + feed/NecessidadeResponseDTO). Mobile: star-rating dialog on accepted matches (Conversar/Prestação/Avaliar actions) + average stars shown on feed cards. api commit abb2ce3, mobile 84c46ad. NOTE: ONG seeing its own rating in the desktop panel left as a small future add (needs a GET /ongs/{id} or fetch). **PHASE C (Confiança & Transparência, blocos 9-11) COMPLETE.**

**PHASE D — Tempo real & Engajamento (July/Aug)**
- 12 [PLUS] WebSocket upgrade of the chat (true real-time, replacing polling) + in-app notifications (e.g. "seu interesse foi aceito").
- 13 [PLUS] Feed melhorado: search/filter by categoria/urgência/cidade; optional simple geolocation.

**PHASE E — Pagamentos (Aug)**
- 14 [STRETCH] Doação financeira: SIMULATED PIX (sandbox/fake), generated receipt. No real gateway/real money for a TCC.

**PHASE F — Segurança & Conformidade (Aug)**
- 15 [PLUS] JWT + refresh token auth (BCrypt already in place); LGPD (consent, privacy policy, terms). Completes "sessões ativas / logout global" from Bloco 8.
- 16 [STRETCH] Audit logs + hardened server-side validation.

**PHASE G — Escalabilidade & DevOps (Aug)**
- 17 [PLUS] DB migrations (Flyway), indexes, normalization review (move off ddl-auto=update).
- 18 [STRETCH] Docker + CI/CD (GitHub Actions) + automated tests (backend unit + Flutter widget). NOTE: microservices = SKIP (over-engineering for this project, low demo value — recommend against).

**PHASE H — Web & Entrega (Aug)**
- 19 [CORE] Web build published (Flutter web doador + institutional portal: sobre, ODS, LGPD, transparência).
- 20 [CORE] Dados de demonstração caprichados (realistic ONGs/necessidades) + demo script.
- 21 [CORE] MASTER FINISH: **strong visual polish pass** (user explicitly flagged 2026-06-24 that the UI is currently "feinho"/plain despite rich functionality — wants it to look genuinely professional). MUST stay in Flutter (school requires the 3 frontends in Flutter; switching UI language is NOT allowed and would discard the apps) — Flutter is fully capable of beautiful UIs, the plainness is just deferred polish. Refine spacing/typography, custom components, micro-animations, empty states, imagery. Can be PULLED EARLIER as a dedicated design block if the user asks. Plus A0 poster review + rehearsal + final testing.

Optional only if time remains after 21 (from original GPT roadmap): recommendation engine, gamification/ranking, chatbot/AI moderation. See [[connect-ong-vision]], [[connect-ong-tech-guidelines]], [[connect-ong-milestones]], [[connect-ong-delivery-rules]], [[connect-ong-banca-feedback]].
