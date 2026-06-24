---
name: connect-ong-profile-settings
description: Detailed spec for the Profile + Settings Center module (roadmap Bloco 8), requested by the user
metadata:
  type: reference
---

User-requested module: **Central de Perfil & Configurações** (added to [[connect-ong-roadmap]] as Bloco 8 — after Design System, [CORE]). Goal: let each user personalize their experience; all settings persisted in the DB and loaded automatically after login. Tech: dedicated **user-preferences table**, reuse existing layered architecture, work on BOTH Flutter desktop and mobile, structured for future expansion, professional UX/UI.

**Scope:**
- **Perfil:** foto, nome, email, telefone, cidade, estado, bio curta. Stats — doador: total doações, ONGs apoiadas, data de cadastro, nível de engajamento; ONG: doações recebidas, nº campanhas, nº apoiadores.
- **Aparência:** tema (claro/escuro/automático), tamanho da fonte (P/M/G), alto contraste, fonte amigável p/ dislexia.
- **Notificações (toggles):** novas mensagens, match, atualizações de campanhas, novas necessidades, notícias da plataforma.
- **Privacidade (toggles):** exibir/ocultar telefone, exibir/ocultar email, perfil público/privado, receber contatos de ONGs, receber sugestões.
- **Segurança:** alterar senha (fluxo completo), sessões ativas (dispositivos), encerrar todas as sessões (logout global).
- **Acessibilidade:** leitura facilitada (fonte dislexia, espaçamento, alto contraste), navegação simplificada.
- **Futuro (estruturar, não implementar agora):** múltiplos idiomas, tradução automática, integração com leitores de tela, personalização avançada.

**My engineering notes / honest dependencies (apply when building):**
- Self-contained NOW: perfil CRUD + foto, appearance settings (theme/font/contrast/dyslexia — these CONSUME the Bloco 7 design system), privacy toggles, notification-preference toggles (stored), change-password endpoint (BCrypt already exists).
- DEPENDS on later blocks: "sessões ativas / logout global" needs real session/token tracking → do it WITH or AFTER the JWT block (Bloco 15); stub/hide until then. Actual notification DELIVERY depends on the notifications block (Bloco 12) — store the prefs now, wire delivery later. Profile stats reuse the same calcs as the impact dashboard (Bloco 4).
- This block is LARGE — may span more than one session; build incrementally (backend preferences table + endpoints → perfil screen → settings screens), self-verifying each step.
