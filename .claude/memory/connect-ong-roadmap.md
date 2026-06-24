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
- 6 [CORE] ONG self-registration + account↔ONG link + finish persona split: ONG signs up → creates a LINKED login + Ong profile; removes the email-bridge/selector hack so the panel knows its ONG natively. ALSO remove the now-redundant ONG/receptor side from the MOBILE app (mobile = doador only): login becomes doador-only (drop the Doador/ONG toggle), delete lib/receptor/* + lib/pedido.dart + receptor routing in main.dart/SplashDecider. (Bloco 5 cleaned the desktop's "Empresa" side; this finishes the symmetric cleanup on mobile.)
- 7 [CORE] Design system & UX: shared theme/palette across mobile+desktop, reusable components, responsiveness, visual feedback states, basic accessibility.

- 8 [CORE] **Perfil & Central de Configurações** (user-requested; full spec in [[connect-ong-profile-settings]]): dedicated user-preferences table; perfil (foto/nome/contato/cidade/estado/bio + stats), aparência (tema claro/escuro/auto, tamanho de fonte, alto contraste, fonte dislexia — consumes the Bloco 7 design system), toggles de notificação e privacidade, alterar senha, acessibilidade. Self-contained parts now; "sessões ativas" waits for the JWT block, live notification delivery for the notifications block.

**PHASE C — Confiança & Transparência (July)**
- 9 [PLUS] Verificação de ONG: selo de verificado, doc/CNPJ field, simple admin approval flow.
- 10 [PLUS] Prestação de contas: ONG posts photos/reports/results on a fulfilled donation; doador can see the outcome.
- 11 [PLUS] Avaliações: doador rates/comments an ONG after a donation.

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
- 21 [CORE] MASTER FINISH: final visual polish + A0 poster content review + rehearsal + final testing.

Optional only if time remains after 21 (from original GPT roadmap): recommendation engine, gamification/ranking, chatbot/AI moderation. See [[connect-ong-vision]], [[connect-ong-tech-guidelines]], [[connect-ong-milestones]], [[connect-ong-delivery-rules]], [[connect-ong-banca-feedback]].
