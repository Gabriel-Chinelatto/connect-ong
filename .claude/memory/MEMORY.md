# Memory Index

> ## 💻 EM OUTRO COMPUTADOR? Siga o [checklist de atualização](connect-ong-atualizar-outro-computador-2026-09-22.md): puxar os 4 repos, pôr `APP_CRYPTO_KEY` local (valor no Render), recompilar FEIRA ESCOLA e substituir os PDFs em `Área de Trabalho\Connect ONG - Entregas`.
>
> ## 🆕 PÓS-FECITEC (2026-09-22) — LEIA PRIMEIRO
> Feira deu **6,6**. Plano de Ação + Entrega Final **feitos e no ar** (docs em `connect-ong/docs/entregas/`): validação de formato nos 4 lados, criptografia AES-256-GCM, LGPD (consentimento/exportação/anonimização), indicadores, páginas Resultados/Para empresas/Segurança no site. Testes 231/124/75. `APP_CRYPTO_KEY` já está no Render e os dados antigos foram todos cifrados (a mesma chave está no CONNECT-ONG-SEGREDOS.txt; o notebook da feira precisa dela se for ler um dump da escola). O site estava quebrado desde 01/09 (corrigido). Ver [Plano de Ação pós-FECITEC](connect-ong-plano-acao-pos-fecitec-2026-09-22.md).
>
> ## 🚀 ESTADO ATUAL (2026-09-01) — LEIA PRIMEIRO  ·  VÉSPERA da apresentação
> **✅ MÁQUINA DA FEIRA 100% PRONTA E CONFERIDA.** Tudo LOCAL por **1 clique**, na pasta **`C:\Users\gabri\OneDrive\Área de Trabalho\FEIRA ESCOLA\`** (a Área de Trabalho é redirecionada pro OneDrive — NÃO é `C:\Users\gabri\Desktop\`; os REPOS continuam em `Desktop\connect-ong` etc.). Scripts: `INICIAR-FEIRA` (sobe tudo + aquece + abre 3 abas), `RESTAURAR-DEMO` (o **"voltar antes"** entre apresentações, **~50s** desde 25/08: repõe as imagens), `PARAR-FEIRA`, `RECOMPILAR-FEIRA`, `RECOMPILAR-APK` (só o APK do emulador, ~8 min), `ATUALIZAR-BANCO-DA-ESCOLA` (véspera), `INICIAR-MOBILE-EMULADOR` (o app no celular simulado), `PASSO-A-PASSO-DO-DIA.txt`. Telas em **0,03–0,26s**. Ver [conferência final](connect-ong-conferencia-final-2026-08-24.md) e [FEIRA ESCOLA](connect-ong-feira-escola-2026-08-13.md).
> **⚠️ CONFERÊNCIA 24/08:** o notebook estava ATRÁS do remoto (correções do grupo de ~20/08). Sincronizei os 4 repos e **reconstruí jar+web da pasta** do código novo (senão a feira usaria versão velha). backend **191 testes verdes**.
> **🤖 IA LIGADA (de verdade):** a chave Groq (`gsk_...`) está em `FEIRA ESCOLA\chave-ia.txt` (fixada always-local; fora de repo). Provado ao vivo `modo:"ia"`, `/ia/status?ping=true`→`ok`. ⚠️ **Groq ≠ Grok:** o projeto usa **Groq** (`gsk_`, api.groq.com, GRÁTIS); NÃO confundir com **Grok/xAI** (`xai-`, PAGO). Se a IA cair, ver `/ia/status` (o modelo pode ter sido aposentado de novo).
> **🖼️ DEMONSTRAÇÃO INTEIRA ILUSTRADA (25/08):** as **2.000 ONGs** têm **logo + capa** coerentes com a causa e os **1.200 doadores** têm retrato — ninguém abre mais um perfil vazio. Coluna nova `ong.logo_base64`; as imagens dos CARDS agora vêm por URL (`GET /publico/ongs/{id}/logo|capa`) e a listagem **deixou de mandar base64** — sem isso `GET /ongs` (2.000 de uma vez) iria de 2,4 MB para ~80 MB. **Achado grave:** o `RESTAURAR-DEMO` **apagava as fotos** (reimporta o dump da escola, que não as tem) — corrigido, mas agora ele leva **~50 s** em vez de ~15 s. Ferramenta: `ferramentas/ilustrar_demo.py`; imagens em `FEIRA ESCOLA\interno\imagens-demo\` (+ CREDITOS.md). Ver [imagens da demo](connect-ong-imagens-demo-2026-08-25.md).
> **⚡ VÉSPERA (01/09):** busca de ONGs com **rolagem infinita** na web e no app (`GET /ongs?pagina&tamanho`, opcional — nada mais quebrou). A aba travava porque a web montava **as 2.000 cards de uma vez** e refiltrava tudo a cada tecla. Também: o **assistente parou de morrer depois de 2 perguntas** (validação do histórico, não a IA) e os **números que ele dizia aos avaliadores foram corrigidos** (191/101/52 = 344 testes). 📌 **Próxima da fila: paginar `/necessidades`** (7.076 itens, 2,68 MB). Ver [paginação da véspera](connect-ong-paginacao-2026-09-01.md).
> **✅ FECHAMENTO 26/08:** `RESTAURAR-DEMO` (**55 s**) e `INICIAR-FEIRA` rodados **inteiros**, de verdade — as imagens voltam e os 5 serviços sobem. Upload de logo pelo painel conferido no contrato do PUT. E achei um problema que a resposta enxuta escondia: o `findAll()` da listagem **carregava** os ~78 MB de base64 que ela nem envia, e o lixo disso derrubava as telas seguintes (`/necessidades` chegou a **8,4 s**). Trocado por projeção: **`GET /ongs` 0,35 s → 0,08 s**, resposta **byte a byte idêntica** (`cmp`).
> **📷 As 6 ONGs do telão** (ids 20/32/33/34/35/36) mantêm as capas escolhidas a dedo. Produção (escola/Render) continua **sem** as imagens — mas ⚠️ o push do backend cria a coluna `logo_base64` lá no próximo deploy (aditiva, nullable).
> **🐛 501 do site RESOLVIDO:** era o `WsToastNotification.exe` (Wondershare) agarrando a porta 8090; `INICIAR-FEIRA` agora o mata antes de subir o site.
> **⏭️ DECISÕES DO USUÁRIO (não fazer sem pedir):** APK no celular DISPENSADO (o emulador basta); senha do MySQL NÃO será rotacionada (risco aceito); fotos NÃO foram pro site publicado (só local). **Único to-do dele:** rodar o fluxo inteiro 1x esta semana pra ganhar confiança.
>
> ## Estado anterior (2026-08-12)
> **Banco RECHEADO para a apresentação:** 2.000 ONGs pelas 27 UFs (coordenada real de município), 1.200 doadores, 909 necessidades abertas, 3.254 prestações, R$ 3,56 mi em PIX; contas da feira com história escrita à mão (Lar Viva é a #1 do ranking e fica com interesses PENDENTES de propósito, para aceitar ao vivo). Ferramentas em `connect-ong-api/ferramentas/`.
> **Última rodada (20/08):** a IA estava **morta havia dias, em silêncio** — a Groq aposentou o modelo e tudo caía no "Modo básico". Corrigido e **verificado na API publicada** (`modo:"ia"`). Antes de apresentar, confira em **`/ia/status?ping=true`**. Ver [IA: modelo aposentado](connect-ong-ia-modelo-aposentado-2026-08-20.md).
> **Rodada anterior (12/08):** o banco cheio revelou três problemas de TELA, todos fechados — carrossel de campanhas estourando a largura, campanha sem caminho para o perfil da ONG e o mapa da web ilegível (agora em 3 níveis: estado → área → ONG). Ver [ajustes pós-recheio](connect-ong-ajustes-pos-recheio-2026-08-12.md), que também traz **como subir os 4 serviços locais** para conferir na tela.
> **🔑 FRASE-CHAVE (já cumprida em 13/08):** "vamos se preparar para a feira no computador de apresentação" → o `PREPARAR-FEIRA.md` foi executado; virou a pasta FEIRA ESCOLA. Não precisa repetir.
> **🔴 A lentidão NÃO é o código nem o volume: é o Render grátis.** Mesma tela, mesmo banco: perfil de ONG 4,85s no Render × **0,81s local**. Ver [massa-demo + feira](connect-ong-massa-demo-e-feira-2026-08-11.md).
> **Testes:** backend **191** · doador **101** · painel **52** (todos verdes em 26/08).
> **🌐 No ar:** site https://connectong.netlify.app · doador https://gabriel-chinelatto.github.io/connect-ong/ · painel https://gabriel-chinelatto.github.io/connect-ong-desktop/ · API https://connect-ong-api.onrender.com + MySQL da escola. `git push` = deploy automático. **Os 4 repos são PÚBLICOS (nunca commitar segredo).**
> **⏰ A API hiberna** (~15 min ociosa; 1ª chamada de 10 a 95s): acordar antes de qualquer apresentação. Se ela CAIR, ler Events/Logs no Render antes de supor hibernação (a causa real já foi estouro de 512 MB).
> **📋 Apresentar:** `COMO-MOSTRAR.md` (repo mobile). Contas: `demo.joao@connectong.com` / `demo.larviva@connectong.com`, senha `demo123`.
> **⚠️ Nome "web":** o portal que o usuário chama de web **é o app mobile no navegador** (`lib/web/portal_institucional_screen.dart`, repo `connect-ong`). O site em HTML puro é outro repo (`connect-ong-web`).
> **🔴 Senha do MySQL exposta no git público:** o usuário DECIDIU NÃO rotacionar (24/08) — risco aceito conscientemente. Não reabrir sem ele pedir. (A feira roda local com usuário `feira`/`feira123`, não usa a senha da escola.)
> **ℹ️ Já resolvidos (não são mais pendência):** fotos reais (feitas, local), chave da IA (ligada), APK no celular (dispensado). Mapa offline já cacheado (1.487 tiles) — feira sem internet funciona. Resta opcional: UptimeRobot p/ o Render; apagar a pasta solta `connect-ong/connect-ong-web/` do disco.

- [Paginação e correções da véspera (2026-09-01)](connect-ong-paginacao-2026-09-01.md) — **rolagem infinita na busca de ONGs** (web e mobile) com `?pagina&tamanho` OPCIONAL no `GET /ongs` (2.000 ONGs/1,23 MB → 24/11 KB); o **assistente que morria depois de 1-2 perguntas** era `@Size(max=1000)` no histórico recusando a própria resposta anterior (400 → "indisponível"); e ele **contava número errado** aos avaliadores (dizia 165 testes; são 344). Traz a regra do fim-da-lista (página VAZIA, não menor) e o **APK quebrado que quase foi para a feira** (Gradle falhou e deixou 41 MB só x86_64). 📌 **Falta:** paginar `/necessidades` (7.076 itens, 2,68 MB).

- [Imagens da demonstração (2026-08-25)](connect-ong-imagens-demo-2026-08-25.md) — **logo + capa nas 2.000 ONGs e retrato nos 1.200 doadores**. Traz o motivo do desenho (a listagem devolve TODAS as ONGs de uma vez: base64 por ONG viraria ~80 MB, daí os endpoints de imagem por URL), o **RESTAURAR-DEMO que apagava as fotos**, a **marca d'água do rawpixel** em 18 das 54 capas e a heurística de causa que erra por pedaço de palavra ("a**cao**" → animais, "comunitá**rio**" → ambiente).

- [Conferência final (2026-08-24)](connect-ong-conferencia-final-2026-08-24.md) — **última semana antes da FECITEC**: o notebook estava ATRÁS do remoto (correções do grupo de 20/08); **jar + builds web da pasta FEIRA ESCOLA reconstruídos** do código novo (191 testes, IA corrigida, painel com guarda); o **501 do site era o `WsToastNotification.exe` (Wondershare NativePush) agarrando a porta 8090** — INICIAR-FEIRA agora mata ele antes de subir o site. Pendências humanas: chave Groq, fotos, APK no celular, senha MySQL.

- [FEIRA ESCOLA (2026-08-13/17)](connect-ong-feira-escola-2026-08-13.md) — pasta única na Área de Trabalho com **RESTAURAR-DEMO (o "voltar antes")**; Dora no modo regras entendendo **"Cidade - UF"** e estados; a **chave do Groq não está neste notebook** (plumbing `chave-ia.txt`, integração de IA centralizada em 8 serviços); **guarda de "descartar alterações" em TODA tela de edição** dos 3 apps. Gotchas: `mvn package` falha com o jar rodando; heredoc do Git Bash quebra.

- [Preparação da feira (2026-08-13)](connect-ong-preparacao-feira-2026-08-13.md) — **máquina de apresentação PRONTA e testada**: MySQL 8 portátil (sem admin) com o banco da escola importado, jar + builds release + APK, scripts de 1 clique (INICIAR/PARAR/RECOMPILAR/ATUALIZAR-BANCO), mapa offline por cache de tiles no serve.py, aquecimento automático. Gotchas novos: **CA do Avast rotaciona**, `findstr` com espaço vira OU, `timeout` do Git Bash sombreia o do Windows.

- [IA: modelo aposentado (2026-08-20)](connect-ong-ia-modelo-aposentado-2026-08-20.md) — a IA "muito limitada" era a IA **morta**: a Groq aposentou o `llama-3.1-8b-instant` (404 em toda chamada) e o fallback silencioso escondeu isso. Traz a **cadeia de modelos** (o limite grátis é 8.000 tokens/min **por modelo**), o `GET /ia/status`, o `reasoning_effort` que muda de valor por família, a **visão que dá 503 em 2 de 3 chamadas**, o "matches" recusado por causa do plural e o **501 do site**: no Windows dá para subir um servidor **por cima de outro, sem erro**.

- [Ajustes pós-recheio (2026-08-12)](connect-ong-ajustes-pos-recheio-2026-08-12.md) — os três problemas que só apareceram com o banco cheio: **carrossel estourando 1.381px** (uma bolinha por campanha), **campanha sem link para o perfil da ONG** e o **mapa em 3 níveis** (estado → área → ONG; agrupar por cidade NÃO resolve, são 1.414 cidades). Mais tarde no mesmo dia, o **redesenho visual do login do doador** (os números saíram porque o portal ANTERIOR já os mostra formatados) + a rota `#login` do harness. Traz **como subir os 4 serviços locais**, a pegadinha do `127.0.0.1` × `localhost` no `serve.py` (2,1s × 0,1s) e a **largura mínima de 500px do Chrome headless**.

- [Massa de demonstração + plano da feira (2026-08-11)](connect-ong-massa-demo-e-feira-2026-08-11.md) — o banco deixou de parecer banco de teste; traz a **frase-chave** que dispara o `PREPARAR-FEIRA.md`, a medição que prova que **a lentidão é o Render**, o **N+1 que só apareceu com o banco cheio** (ranking de 0,3s para +180s) e as armadilhas do banco **latin1** da escola.

- [Varredura + bugs do grupo (2026-08-10)](connect-ong-varredura-2026-08-10.md) — a ONG **não conseguia salvar nada no perfil** (e-mail escondido no GET voltava vazio no PUT e estourava 500); IA do dev com conhecimento real + recusa fora de escopo; correções da web (mapa escuro, busca invisível, comparador, duplo clique); aviso de alterações não salvas nos 3 apps; erro do cliente deixou de virar 500. Armadilhas: `ONGService.java` renomeado pelo Windows, overlay que perde o clique pelo foco, testar a API **com token**.

- [Hospedagem + quedas da API (2026-08-05)](connect-ong-hospedagem-2026-08-05.md) — os 3 frontends publicados e a causa real das quedas (**estouro dos 512 MB**, não hibernação). Pegadinhas do GitHub Pages (habilitar na mão, `--base-href`, CORS), Modo Feira desligado só no publicado, e por que o ping por GitHub Actions não resolve a hibernação.

- [Feedback do app (2026-08-03)](connect-ong-feedback-app-2026-08-03.md) — portal com um único caminho de login, documentos legais redesenhados, foguinho cortado, chat que sumia no tema escuro, performance e **timeout adaptativo** para a hibernação. Contém o **harness de screenshots** (Chrome headless) e **como rodar os três apps** (portas 5000/5001/8090, `serve.py`, liberar a porta presa pelo `dartvm`).

- [Endereço + mapa por coordenada (2026-07-29)](connect-ong-endereco-mapa-2026-07-29.md) — autocomplete Nominatim no painel, colunas lat/lng no backend, mapa/Maps por coordenada exata, performance do desktop.

- [Web = Doador (no ar)](connect-ong-web-doador-plano.md) — repo separado em HTML/CSS/JS puro (`connect-ong-web`), proxy same-origin do Netlify (sem CORS), variáveis de ambiente do Render, features exclusivas da web (mapa, comparador, quiosque, Ctrl+K) e o chat "Sobre o Desenvolvimento" nos 3 frontends.

- [Inventário do Doador](connect-ong-inventario-doador.md) — catálogo completo das 27 telas, 26 serviços e endpoints do doador.

- [Frete + IA (2026-07-10)](connect-ong-frete-e-ia-2026-07-10.md) — simulador de frete (IBGE offline + Haversine) e IA Groq em 5 frentes, com auditoria de prompts e temperatura por tarefa.

- [Engajamento (2026-07-10)](connect-ong-engajamento-2026-07-10.md) — dias esperando, recusa que reabre, datas de status, sub-abas do painel, foto na avaliação ONG→doador, toast in-app.

- [Auditoria final](connect-ong-auditoria-final.md) — revisão de segurança com todos os achados de código fechados (XFF, rate limit, privacidade, Modo Feira).

- [Assistente de IA](connect-ong-assistente-ia.md) — chatbot de doação (Groq + fallback por regras), chave só no backend, grounding com dados reais.

- [Sessão 2026-07-06](connect-ong-sessao-2026-07-06.md) — bloqueio estilo WhatsApp, UF/cidades IBGE offline, privacidade real, acessibilidade, Maps.

- [Arquitetura](connect-ong-architecture.md) — 3 repos + regra dos 3 frontends (mobile=doador, desktop=ONG, web), API e MySQL remoto.
- [Roadmap](connect-ong-roadmap.md) — roadmap 100% concluído (blocos 0-30) + seções pós-roadmap.
- [Backlog adiado](connect-ong-deferred.md) — restam itens de infra/decisão: senha do MySQL, utf8mb4, Docker, upload de imagens, WebSocket.
- [Remodelagem do mobile](connect-ong-remodel-mobile.md) — bloco 21 concluído; build Windows depende do VS C++.
- [Rodada de qualidade + segurança](connect-ong-hardening-pass.md) — IDOR, JWT obrigatório, esqueci-senha E2E, rate limiting.
- [Perfil e configurações](connect-ong-profile-settings.md) — spec do centro de configurações.
- [Visão do produto](connect-ong-vision.md) — tratar como produto real; papéis DOADOR/ONG.
- [Marcos](connect-ong-milestones.md) — FECITEC 31/08 a 02/09, final em novembro.
- [Feedback da banca](connect-ong-banca-feedback.md) — a banca quer interação; feature-herói = match + chat.
- [Regras de entrega](connect-ong-delivery-rules.md) — commits por integrante, RESTful, 3 frontends, pôster A0 + MVP.
- [Padrões técnicos](connect-ong-tech-guidelines.md) — stack fixa e regra de performance.
- [Git](git-workflow-preferences.md) — **auto-commit + auto-push** a cada checkpoint, sem pedir; sem co-autoria do Claude; mobile/desktop=main, backend=master.
- [Idioma](preferencia-idioma.md) — **tudo em português** (respostas, commits, comentários, docs, UI).
- [Memórias](preferencia-memoria-opus.md) — escrever memórias autoexplicativas (o porquê + arquivo/commit/rota concretos).
- [Permissões](permissoes-projeto.md) — não pedir confirmação de permissão neste projeto.
- [Gráficos](preferencia-graficos.md) — SVG/imagens livres, autorais nas cores da marca.
- [Notebook FECITEC](connect-ong-notebook-fecitec.md) — 2ª máquina (user `gabri`): caminhos dos repos, JDK 21, Android SDK, scripts.
- [Java + Avast TLS](ambiente-java-avast-tls.md) — o Avast intercepta HTTPS e quebra ferramentas Java (PKIX); importar a CA no cacerts.
