---
name: connect-ong-auditoria-final
description: "Auditoria final de segurança/qualidade do Connect ONG (2026-07-06, 2 agentes read-only backend+apps) — achados priorizados, quick wins a corrigir, decisões conscientes e ações do usuário. Ponto de partida p/ o próximo chat."
metadata: 
  node_type: memory
  type: project
  originSessionId: 5efb506b-4e50-4863-bb56-8bc40ab1a110
---

Auditoria pedida pelo usuário ("analise todo o projeto, aponte falhas de segurança/erros/ambiguidades") em 2026-07-06, quando ele considerou o projeto "basicamente pronto". Feita por 2 subagentes SOMENTE-LEITURA (backend security+correção; apps Flutter mobile+desktop) + síntese. **Veredito: projeto maduro/bem defendido p/ TCC; nada Crítico com config de produção correta.** Ver também [[connect-ong-deferred]] (backlog) e [[connect-ong-assistente-ia.md]].

## 🔴 FALHAS REAIS A CORRIGIR (priorizadas) — quick wins = itens 2,4,5,6
1. **[ALTA] Modo Feira ligado por padrão** — `application.properties` `app.demo.enabled=${APP_DEMO_ENABLED:true}`. Com demo on, `SenhaResetService.solicitar` devolve `codigoDemo` no JSON (SenhaResetService.java:108-110) e o desafio 2FA idem (UsuarioService.java:219-221) → qualquer um reseta/burla 2FA de qualquer conta = **account-takeover se publicado sem `APP_DEMO_ENABLED=false`**. Intencional p/ a feira, mas o DEFAULT é perigoso. FIX: inverter default p/ `false` e ligar só na máquina da feira (o `app.security.enforce` já é true por padrão — aplicar o mesmo critério).
2. **[MÉDIA] Privacidade de contato contornável** — `GET /ongs` (ONGService.listar/toDTO :236-264,:420-433) e `GET /ongs/{id}` (obterPorId/toDTORico :306-312) devolvem email/telefone/cnpj de qualquer ONG p/ qualquer autenticado, IGNORANDO os toggles mostrarEmail/mostrarTelefone (só o perfil-publico respeita, via `aplicarPrivacidade` :144-165). FIX: aplicar `aplicarPrivacidade`/omitir contato também nesses 2 caminhos. **(quick win)**
3. **[MÉDIA] Rate limit + IP de audit confiam em X-Forwarded-For sem proxy** — RateLimitService.java:151-153 (e AuditService). API exposta direto → cliente forja XFF e burla anti-brute-force do login (chave email+IP, UsuarioService.java:184), limite de cadastro/esqueci-senha/cota da IA, e falseia IP no audit-log. FIX: usar getRemoteAddr() sem proxy; com proxy, aceitar XFF só do IP do proxy.
4. **[MÉDIA] Mobile trava com token expirado** — sem tratamento GLOBAL de 401. `main.dart:147` (SplashDecider) decide rota só pelo UsuarioLogado persistido; token vencido → entra no MainShell e tudo dá 401 sem deslogar (só há 401 pontual em configuracoes_screen.dart:486 e perfil_service.dart:83). FIX: interceptar 401 no ApiService._executar → SessionService.logout() + volta ao login. **(quick win, alto valor p/ estabilidade na feira)**
5. **[MÉDIA] `fromJson` frágil nos 2 apps (int×bool / null)** — models fazem `id: json['id']` sem cast e `urgente: json['urgente'] ?? false` (mobile models/usuario_logado.dart:29-35, necessidade; desktop models/necessidade.dart:25). MESMA classe do bug do `doisFatores` (backend manda 0/1, app espera bool → crash). FIX: casts tolerantes (`(json['id'] as num?)?.toInt() ?? 0`; `json['urgente']==true || json['urgente']==1`). **(quick win)**
6. **[BAIXA] `/auth/refresh` não checa soft-delete** — AuthController.java:99-108 só faz findById; conta excluída segue emitindo access token por 7 dias via refresh (login/2FA/reset já barram soft-delete). FIX: rejeitar se dataExclusao != null. **(quick win, 1 linha)**
7. **[BAIXA] `POST /ongs` legado** cria ONG "fantasma" sem dono (qualquer logado, ONGController.java:76-83) — spammável; fluxo real é /ongs/registro. FIX: restringir a ADMIN ou remover. (Mass-assignment de id NÃO se aplica — entidades sem setId público.)
- Nota menor: `POST /campanhas/{id}/contribuir` aceita doadorNome do corpo (cosmético/spoofável) e sem rate limit (CampanhaController.java:49-60).

## 🟡 DECISÕES CONSCIENTES (documentar p/ a banca, não "corrigir")
- JWT sem revogação (logout/exclusão não invalidam token já emitido; vale até expirar ~12h).
- Token no SharedPreferences em texto puro (mobile; na web = localStorage). Citar flutter_secure_storage como evolução.
- PIX/2FA/e-mail SIMULADOS (sem gateway/SMTP). Correto p/ TCC.
- Itens de doação legados sem dono editáveis (DoacaoService.java:106-111,158-163) — catálogo antigo, risco baixo reconhecido.
- utf8mb4 pendente (emoji só na UI, nunca persistido).

## 🔧 AÇÕES DO USUÁRIO (fora do código)
- **Senha do MySQL da escola AINDA no histórico do git** — rotacionar + limpar histórico (BFG/git-filter-repo). Item de segurança concreto mais relevante que resta. (Ver [[connect-ong-deferred]].)
- **Chave da Groq passou pelo chat** (gsk_...) — se quiser zerar risco, gerar nova no console.groq.com (revoga a atual). Está gitignored, nunca foi commitada.

## ✅ O QUE JÁ ESTÁ SÓLIDO
IDOR bem fechado (exigirUsuario/exigirOng/exigirParticipante consistentes; identidades sempre do token, nunca do corpo; listar interesses bloqueia findAll sem filtro). ROLE_ADMIN dedicado não auto-provisionável (fim da auto-verificação de ONG). Segredos fora do git (JWT secret obrigatório sem default; senha e chave Groq só em application-local.properties gitignored — CONFIRMADO não versionado; application.properties só tem ${ENV}/placeholders; chave Groq nunca logada). Login anti-enumeração (401 genérico) + BCrypt + soft-delete barrado + tipo forçado DOADOR no cadastro. Assistente IA sem vazamento (grounding só público + histórico do próprio usuário pelo id do token; sanitiza ids; rate limit; @Size na imagem). Validação @Valid + limites em todo base64 (3-6MB, máx 5 fotos). GlobalExceptionHandler sem stacktrace. 100% JPQL com params nomeados (sem injeção). Soft-delete respeitado em login/listagens/perfis/assistente/estatísticas. Apps: ZERO segredo no cliente, logout limpa sessão+token, imagens comprimidas com teto, privacidade de contato aplicada no servidor. Desktop: token só em memória (re-login a cada abertura). analyze limpo nos 2 apps; testes: backend 135, mobile 81, desktop 38.

## PRÓXIMO PASSO SUGERIDO (p/ o novo chat)
Se o usuário quiser, aplicar o PACOTE DE QUICK WINS: itens 2 (privacidade GET /ongs), 4 (interceptor 401 mobile), 5 (fromJson bool/int nos 2 apps), 6 (refresh soft-delete) + inverter o default do item 1 (deixando `true` na máquina da feira). Todos baixo risco/alto valor. Com teste + verificação + commit/push (padrão da sessão: [[git-workflow-preferences]]).
