---
name: connect-ong-deferred
description: "Connect ONG — backlog único de itens ADIADOS durante os blocos (recapitular após o Bloco 30 se sobrar tempo)"
metadata:
  node_type: memory
  type: project
  originSessionId: fd5869c2-ce42-4ab3-b411-545f30b4d907
---

Backlog de coisas conscientemente **deixadas para depois** ao longo dos blocos. Recapitular após terminar os 30 blocos (ver [[connect-ong-roadmap]]). Cada item: origem → o quê → por que adiado. Marcar com ✅ quando resolvido.

## Segurança / conformidade
- **[x] JWT enforcement** (Bloco 15 → FEITO 2026-06-26): ATIVADO. Spring Security real no backend (`SecurityFilterChain` + `JwtAuthFilter` validando o Bearer), whitelist pública (`/auth`, `/publico`, swagger, `POST /usuarios`, `/usuarios/login`, `/ongs/registro`), CORS central (não mais `*`), JWT secret via `app.jwt.secret`/env, senha `WRITE_ONLY`, DTOs com `@Valid` no cadastro/login (fecha mass assignment), login 401 genérico. Os 3 apps enviam `Authorization: Bearer` (mobile persiste token em SharedPreferences; desktop em memória pois não persiste sessão). Toggle `app.security.enforce` (default true) = válvula de escape p/ feira. Access token = 12h.
- **[x] Autorização por DONO (ownership)** (FEITO 2026-06-26): principal `UsuarioAutenticado` (id/tipo/ongId do token) + `SecurityUtils.exigirUsuario/exigirOng/exigirUsuarioOuOng` + `AcessoNegadoException`→403. Aplicado em perfil/senha/preferências, notificações, favoritos, doações financeiras, interesses (listar/demonstrar e aceitar/recusar só pela ONG dona), avaliar, e chat (só participantes do match). Apps NÃO precisaram mudar (já mandam o próprio id = id do token; usuário-ONG tem ongId, inclusive nos dados de demo). Provado por `SecurityEnforcementTest` (8 testes: acesso a perfil/notificação de outro → 403). **Pendente futuro (nice-to-have):** `@PreAuthorize` por papel.
- **[ ] Senha do banco no histórico do git** (sessão inicial): a senha foi externalizada para `application-local.properties` (gitignored), MAS commits antigos ainda contêm a senha em texto puro no histórico. **AÇÃO DO USUÁRIO, NÃO FEITA:** rotacionar a senha do MySQL da escola (`cl*28032008` @ 143.106.241.3) E limpar o histórico (BFG/git filter-repo). Idem definir `APP_JWT_SECRET` novo em prod.
- **[x] JWT secret sem default hardcoded** (FEITO 2026-07-02): `JwtService` agora usa `@Value("${app.jwt.secret}")` SEM default — a app FALHA no startup sem a chave (antes um default público no código permitia forjar tokens). Chave forte adicionada ao `application-local.properties` (gitignored, dev) e placeholder no `.example`. Commit backend `1497be0`.
- **[x] IDOR corrigido em massa** (FEITO 2026-07-02, commits `fac1ecb`+`fa5410f`): antes qualquer logado podia apagar/editar/**auto-verificar QUALQUER ONG**, publicar necessidades/campanhas em nome de ONGs alheias, encerrar campanhas de terceiros e ler prestações de outros; audit-logs e denúncias eram lidos por qualquer um. Agora: `SecurityUtils.exigirOng(...)` em ONG(atualizar/deletar/verificar)/Necessidade(criar)/Campanha(criar/encerrar), `exigirParticipante` em Prestação(listar/criar), `/audit-logs` e `GET|PUT /denuncias` restritos a `ROLE_ONG`, mass assignment no `POST /ongs` zerado (verificada/notaMedia), `@Size(max=3MB)` em fotoBase64, senha padronizada em min 6. +2 testes (25/25 passam). **Pendente futuro:** verificar-ONG idealmente deveria ser `ROLE_ADMIN` (hoje ainda permite auto-verificação da própria ONG, pois não há conceito de admin) — criar papel admin.
- **[ ] Rate limiting no login** (força bruta) e **enumeração de e-mails no cadastro** (mensagem "Email já cadastrado" revela existência): apontados na auditoria de 2026-07-02, esforço médio, não feitos.

## Banco de dados
- **[ ] Migrar para utf8mb4** (gotcha recorrente): o MySQL 5.6 usa utf8 (3 bytes) → emojis (4 bytes) dão 500 "Incorrect string value" ao salvar. Hoje contornamos não salvando emoji no banco. Fix definitivo = migrar colunas para utf8mb4.
- **[ ] Baseline completo no Liquibase** (Bloco 17): as tabelas existentes não estão no changelog (predatam o Liquibase). Gerar baseline com `liquibase generateChangeLog` para reproduzir o schema do zero. (Documentado em docs/NORMALIZACAO.md.)
- **[ ] Remover tabela legada `doacao`** (Bloco 17): existe no banco mas não faz mais parte do fluxo. (OBS: a tabela `projeto` NÃO é morta — será reaproveitada como Campanha no Bloco 22.)
- **[ ] FK formal em `usuario.ong_id`** (Bloco 17): hoje é vínculo por id sem constraint; avaliar adicionar FK para integridade referencial no nível do banco.

## DevOps
- **[ ] Validar build da imagem Docker** (Bloco 18): Dockerfile/compose criados mas NÃO validados localmente (Docker não está instalado na máquina). Rodar `docker compose up --build` quando houver Docker.
- **[ ] Hospedar o build web** (Bloco 19): `flutter build web` OK, mas não publicado. Deploy opcional em GitHub Pages/Netlify para ter URL pública.
- **[ ] Push para ativar as CIs** (Bloco 18): os 3 workflows do GitHub Actions rodam no push/PR; ainda não foram pushados (regra: só pushar quando o usuário pedir).

## Funcionalidades
- **[x] Cadastro de doador no mobile** (FEITO no Bloco 21, sessão 2026-07-02): `POST /usuarios/registro` público + `pages/cadastro_doador_page.dart` multi-passo com auto-login. Falta ainda: checkbox de consentimento LGPD e "Esqueceu a senha?" (não há fluxo de reset — apontado na auditoria).
- **[ ] "Esqueceu a senha?"** (auditoria 2026-07-02): login mobile e desktop não têm reset de senha; usuário que esquece fica trancado. Precisa endpoint de reset (por e-mail ou via equipe).
- **[ ] Upload de imagens** (absorvido do roadmap #16): logo da ONG, foto de perfil e fotos de prestação hoje são `fotoUrl` (string), sem mecanismo de upload real. Adicionar quando necessário.
- **[ ] Lista "doações recebidas" no painel da ONG (desktop)** (Bloco 14): a ONG já recebe notificação de doação PIX, mas não há uma tela listando as doações financeiras recebidas. Pequeno add futuro.
- **[ ] WebSocket no chat** (Bloco 11): decisão foi usar polling (2s) agora; WebSocket adiado para real-time mais eficiente.

## Visual
- **Polimento visual forte** = Bloco 21 (já é um bloco planejado do roadmap, não um item solto). Usuário sinalizou (2026-06-24) que a UI está "feinha" apesar da funcionalidade rica.
