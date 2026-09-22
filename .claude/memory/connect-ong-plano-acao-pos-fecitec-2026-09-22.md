---
name: connect-ong-plano-acao-pos-fecitec-2026-09-22
description: "Plano de Ação pós-FECITEC (nota 6,6) — entregas em docs/entregas, validação/criptografia/LGPD/indicadores no ar, APP_CRYPTO_KEY pendente no Render, site estava quebrado desde 01/09"
metadata: 
  node_type: memory
  type: project
  originSessionId: 35ee9f2c-3528-4c40-8211-458efb836d58
  modified: 2026-09-22T12:52:18.630Z
---

**Contexto:** FECITEC deu média **6,6** (Q13 Segurança = 3, Q5 Modelo de Negócios = 4, Q4 Dados = 5). O professor pediu (PDF "plano_de_acao_projeto_integrador"): Entrega 1 = Plano de Ação (backlog MoSCoW com TODOS os pontos da banca + feira), Entrega 2 = vídeo 5–10 min + rastreabilidade (4.2) + retrospectiva (4.3). Em 22/09/2026 foi feito TUDO num dia só.

**Documentos (repo mobile, `docs/entregas/`):** `Connect-ONG-Plano-de-Acao.pdf` (Entrega 1, IDs B-01..B-05 da banca e F-01..F-15 da feira) e `Connect-ONG-Entrega-Final.pdf` (rastreabilidade, prints, modelo de negócios/Lean Canvas, segurança/LGPD, roteiro do vídeo com quem fala, retrospectiva RASCUNHO). HTML-fonte + `estilo.css`; PDF gerado com `chrome --headless=new --no-pdf-header-footer --print-to-pdf`. Responsáveis no plano: Gabriel, Abner, Luan, Arthur (nomes do app).

**O que entrou no código (commits 22/09):** API `061c300`+`c28b59f`, app `514f79b`+`269df35`, painel `654f7f3`+`2803e87`, site `ca603e0`, docs `10e30fc`.
- **Validação de formato:** `validacao/Regras.java` (telefone c/ DDD Anatel, CNPJ c/ DV incl. alfanumérico 2026, NomeProprio, TextoLegivel sem `<>`, Uf, SenhaForte 8+ letra+número, PeriodoCampanha). ESPELHADA em `utils/validadores.dart` (app E painel, mesmo arquivo) e `js/validadores.js` (site) — mudou uma, mude as 4. Senha de teste padrão agora é `doacao2026` (`123456`/`senha123` são recusadas). Cadastro exige `aceiteTermos: true`.
- **Criptografia AES-256-GCM** (`security/Criptografia` + `CampoCifradoConverter`) em `usuario.telefone`, `mensagem.conteudo`, `denuncia.descricao`; códigos de reset/2FA viraram HMAC. `CriptografiaMigracao` cifra o legado no startup e grava a **impressão digital** da chave na tabela `cripto_chave`: ambiente com chave diferente **NÃO SOBE** (proposital).
- **LGPD:** tabela `consentimento`, `GET /usuarios/{id}/meus-dados`, `/consentimentos`, exclusão anonimiza (`LgpdService`). Telas "Privacidade e meus dados" no app, painel (salva arquivo no Windows) e site (download JSON).
- **Indicadores:** `GET /publico/indicadores` (cache 10 min) e `/ongs/{id}/indicadores` — UNION ALL numa consulta (regra dos 600 ms). Em produção: 3,0 s frio / 0,25 s com cache.
- **IA:** `RedatorDadosPessoais` tira e-mail/telefone/CPF/CNPJ antes da Groq; aviso nas telas.
- Site ganhou páginas Resultados, Para empresas, Segurança e LGPD. `GET /publico/seguranca` mostra o que está ativo.
- Testes: backend **231**, app **124**, painel **75** (= 430). `conhecimento_dev.md` atualizado com isso.

**🔴 PENDENTE (humano): definir `APP_CRYPTO_KEY` no Render.** Valor em `C:\Users\01gabriel.MAQCHINELATTO\CONNECT-ONG-SEGREDOS.txt` (e em `application-local.properties` desta máquina, gitignored). Enquanto não definir, produção roda com criptografia DESLIGADA (`/publico/seguranca` → `criptografiaEmRepouso:false`), sem quebrar nada. **Why:** o JWT secret do Render ≠ local, então a chave NÃO pode ser derivada dele (versão inicial fazia isso e foi trocada antes do push). **How to apply:** a MESMA chave precisa ir para o notebook da feira (`gabri`) se ele for ler um dump da escola já cifrado — senão aparece "[conteúdo protegido indisponível]"; e qualquer colega que rode o backend contra o banco da escola precisa dela, ou o backend recusa subir.

**Achado grave:** o site publicado estava **quebrado desde 01/09** (`}` sobrando em `pintarRodapeOngs`, commit `95a42c4`) — o `app.js` inteiro não carregava. Corrigido em `ca603e0`. Lição: checar o console do Chrome (`--enable-logging=stderr --v=0 --dump-dom` e grep "Uncaught") antes de dar o site como pronto; não há Node nesta máquina para `node --check`.

**Prints logados:** `chrome --screenshot` TRAVA no site logado (polling do sino/chat) — usar CDP (`--remote-debugging-port` + `websocket-client` num venv temporário), gravando `co_token`/`co_user` no localStorage. Harness Flutter `lib/main_screenshots.dart` (app e painel) agora pega os ids do LOGIN (antes ongId 33 fixo) e tem `#meus-dados` / `#indicadores`; servir o build em `localhost:5000/5001` (origens aceitas pelo CORS). Backend local SEGURO para testes: `mvnw spring-boot:run -Dspring-boot.run.useTestClasspath=true` com `--spring.datasource.url=jdbc:h2:mem:...` por argumento (NUNCA subir o backend local contra o banco da escola sem necessidade).

**Ainda com a equipe:** vídeo (roteiro na seção 7), revisar a retrospectiva, F-09 (visitar ONGs de Limeira), F-11 (commits por integrante — o histórico é quase todo do Gabriel, e a avaliação olha isso), entregar o Plano de Ação na aula. F-12 (paginar `/necessidades`) não feito. Ver [[connect-ong-delivery-rules]], [[connect-ong-auditoria-final]].
