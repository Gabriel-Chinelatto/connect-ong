---
name: connect-ong-hardening-pass
description: "Connect ONG — rodada de qualidade/segurança 2026-07-02 (pós-Bloco 21): o que foi feito nos 3 repos, por quê, commits e o que ficou pendente"
metadata: 
  node_type: memory
  type: project
  originSessionId: c1abd730-01fc-4921-9d41-406ae339005c
---

Rodada de melhorias de QUALIDADE + SEGURANÇA em 2026-07-02, depois do Bloco 21 estar concluído, a pedido do usuário ("investigue e sugira/implemente melhorias em acessibilidade, desempenho, funcionalidade, tooltips, tratamento de erros, validação de entrada, segurança contra SQL injection e outros ataques, + melhorias visuais"). Método: 3 auditores paralelos (mobile, desktop, backend-segurança) → implementação priorizada por risco/retorno → verificação (analyze/test) → commits por checkpoint. Ver também [[connect-ong-deferred]] (backlog atualizado) e [[connect-ong-remodel-mobile]].

## Backend (repo connect-ong-api, branch master) — SEGURANÇA
Auditoria: SEM SQL injection (JPA parametriza tudo). Problemas reais = IDOR + segredo JWT. Corrigido:
- **JWT secret sem default** (`1497be0`): `JwtService` era `@Value("${app.jwt.secret:<default-publico-no-codigo>}")` → qualquer um forjava token. Agora `@Value("${app.jwt.secret}")` sem default (app falha no startup sem a chave). Chave forte no `application-local.properties` (gitignored, dev) + placeholder no `.example`. **Por quê:** o default hardcoded quebrava toda a autenticação.
- **IDOR** (`fac1ecb`+`fa5410f`): antes QUALQUER logado apagava/editava/**auto-verificava qualquer ONG**, publicava necessidade/campanha em nome de ONG alheia, encerrava campanha de terceiro, lia prestação de outro, lia audit-logs/denúncias. Fix com `SecurityUtils.exigirOng(...)`/`exigirParticipante(...)` (padrão que já existia em Doacao/Interesse/Mensagem) + `/audit-logs` e `GET|PUT /denuncias` restritos a `ROLE_ONG` no SecurityConfig + mass assignment zerado no `POST /ongs` + `@Size(max=3MB)` fotoBase64 + senha min 6. **Por quê:** o selo "verificada" é o pilar de confiança do app; IDOR permitia fraude. 25/25 testes (2 novos provam 403 p/ não-dono).

## Mobile (repo connect-ong, branch main) — 4 commits: 6f7dfd2, 34a190d, 5a8475e, 5d4010e
- **Rede robusta** (`ApiService`): wrappers get/post/put/delete com `.timeout(12s)` + `mensagemAmigavel(erro)` traduzindo SocketException/TimeoutException. **Por quê:** sem isso, rede caindo (Wi-Fi FECITEC) = spinner infinito.
- **AppTextField estendido**: keyboardType, maxLength, inputFormatters, textInputAction, onSubmitted, e olho mostrar/ocultar senha. Novo `lib/utils/formatters.dart` (UpperCaseTextFormatter p/ UF). Aplicado em login, cadastro multi-passo, editar_perfil, cadastrar_doacao, doar_pix. **Por quê:** campos aceitavam lixo (UF ilimitada, telefone alfabético, PIX R$0,001).
- **Guard anti-duplo-toque** em "Tenho interesse" (feed) e "Doar via PIX" (setState(enviando=true) ANTES do await). **Por quê:** duplicava interesses/doações.
- **Estado de erro com "Tentar de novo"** (usa EmptyState com icone cloud_off) em Feed, Matches, Impacto — distingue "sem dados" de "API caiu". Login com validação local + Enter submete.
- **Acessibilidade**: Semantics(button:true) nos cards/atalhos da Início, tooltips faltantes (chat/busca), touch target das ações de match →TextButton (≥48px).
- **Visual**: AnimatedSwitcher no botão interesse→enviado, Hero('avatar-doador') perfil↔editar, AppBar do PIX no tema (era verde fixo, ignorava dark mode).

## Desktop (repo "connect_ong - Desktop", branch main) — 4 commits: 18984ad, 805ebd4, f56819d, 4590e8a
Tinha app_colors/app_theme mas as telas NÃO usavam o tema (~89 Colors.* hardcoded quebravam o dark mode que o próprio app oferece). Feito:
- **Design system portado do mobile**: app_spacing, app_radius, utils/categorias, widgets/feedback/empty_state + app_snackbar. Adicionado `AppColors.info` (faltava) e `ApiService.mensagemAmigavel`.
- **Categorias canônicas**: os 2 campos de categoria eram TEXTO LIVRE (painel necessidade/campanha) → viraram DropdownButtonFormField com `Categorias.todas`. **Por quê:** "Alimento" (desktop) não batia com "Alimentos" (mobile/backend).
- **Dark mode** corrigido nas telas visíveis (painel, login, chat, mural, ranking, conquistas, notificações, cadastro).
- **Login**: Enter entra, autofocus, mostrar senha; `auth_service` relança falha de conexão (era `catch→null` que virava "login inválido" com servidor fora do ar). Future.wait na carga do painel + tela de erro com retry. e.toString() cru → mensagemAmigavel.

## PENDÊNCIAS (não feitas — decisão/ação do usuário; ver [[connect-ong-deferred]])
1. **Rotacionar senha do MySQL da escola** (usuário `cl203161`@143.106.241.3 — senha só no `application-local.properties`, gitignored; NÃO escrever aqui: repo PÚBLICO) e limpar histórico do git (BFG) — a senha antiga é recuperável em commits antigos do repo público. **URGENTE**: grant é `@'%'` (aceita qualquer host). AÇÃO MANUAL.
2. **Papel ROLE_ADMIN** p/ conceder selo "verificada": o fix impede estranho verificar, mas ainda permite a ONG se auto-verificar (não há admin no sistema).
3. Menores: consentimento LGPD no cadastro mobile, limpar Colors.* restantes em `perfil_publico_ong_screen` (desktop), snackbars do painel desktop ainda com Colors.red/orange.
4. ~~rate-limiting no login / enumeração de e-mail / esqueci-senha~~ → **RESOLVIDOS no backend em 2026-07-03** (ver seção abaixo); falta só as TELAS de "esqueci a senha" no mobile/desktop consumirem o contrato.

## Backend 2026-07-03 — esqueci-senha + rate limiting + bug B2 (commits `381eb0e`, `d54b034`)
- **Esqueci a senha (contrato FIXO, frontends construídos contra ele):** `POST /auth/esqueci-senha` {email} → SEMPRE 200 `{"mensagem":"Se o e-mail existir, enviaremos um código de recuperação."}` (anti-enumeração; soft-deleted idem, sem gerar código) + campo extra `codigoDemo` quando `app.demo.enabled=true` (simulação de e-mail p/ feira, sem SMTP — precedente do PIX simulado). `POST /auth/redefinir-senha` {email,codigo,novaSenha≥6} → 200 `{"mensagem":"Senha redefinida com sucesso."}`; qualquer falha → 400 `{"erro":"Código inválido ou expirado."}`. Código 6 dígitos SecureRandom, 15 min, tabela `senha_reset` (changeset Liquibase idempotente, `usado_em datetime` em vez de boolean — gotcha BIT/TINYINT), novo código invalida os anteriores. Audit SENHA_RESET_SOLICITADO/SENHA_REDEFINIDA (nunca loga código/senha). Classes: `SenhaResetService`, `SenhaReset`, `SenhaResetRepository`, DTOs Esqueci/RedefinirSenhaDTO.
- **Rate limiting** (`RateLimitService`, in-memory ConcurrentHashMap): login 5 falhas consecutivas por email+IP → 429 15min (sucesso zera); esqueci-senha e cadastros públicos (/usuarios, /usuarios/registro, /ongs/registro) máx 5/15min por IP; redefinir-senha após 5 códigos errados por email → sempre 400 genérico (sem 429, preserva o contrato). Props `app.ratelimit.*`; nos testes o properties compartilhado DESLIGA os limites (MockMvc compartilha IP 127.0.0.1) e `RateLimitTest` restaura os reais via @TestPropertySource.
- **Bug B2:** POST /favoritos e /campanhas/{id}/contribuir liam Map cru (Long/Double.valueOf → 500 em entrada não numérica) → DTOs tipados `FavoritoRequestDTO`/`ContribuicaoRequestDTO` com @Valid → 400; mesmos nomes de campo (contrato intacto, string numérica segue aceita).
- **Testes: 62 (eram 40), 100% verdes**; teste ao vivo com H2 na porta 8099 via `.\mvnw.cmd spring-boot:test-run` (usa classpath+properties de teste; NÃO toca o MySQL da escola).

## Build/ambiente
- `flutter build windows` (mobile E desktop) exige **Visual Studio "Desktop development with C++"** (flutter doctor) — NÃO instalado nesta máquina. Modo Desenvolvedor já OK. Verificação de desktop foi feita via `flutter run -d chrome/web-server` (funciona). Alternativa p/ .exe: notebook FECITEC.
- Contas demo (após `POST /demo/seed` autenticado): `demo.joao@connectong.com` / senha `demo123`.
