# Memory Index

> ## 🚀 ESTADO ATUAL (2026-08-13) — LEIA PRIMEIRO
> **✅ MÁQUINA DE APRESENTAÇÃO PRONTA:** o `PREPARAR-FEIRA.md` foi EXECUTADO em 13/08 no notebook `gabri` — MySQL portátil local com o banco copiado da escola, API em jar, 3 frontends em build release, APK gerado, mapa offline, tudo por **1 clique** (`INICIAR-FEIRA.bat` na Área de Trabalho, com aquecimento automático). Telas que levavam 4,85s no Render respondem em **0,10–0,45s**. Ver [preparação da feira](connect-ong-preparacao-feira-2026-08-13.md). Falta só: instalar o APK no celular (cabo) e, na véspera, rodar `ATUALIZAR-BANCO-DA-ESCOLA.bat`.
>
> ## Estado anterior (2026-08-12)
> **Banco RECHEADO para a apresentação:** 2.000 ONGs pelas 27 UFs (coordenada real de município), 1.200 doadores, 909 necessidades abertas, 3.254 prestações, R$ 3,56 mi em PIX; contas da feira com história escrita à mão (Lar Viva é a #1 do ranking e fica com interesses PENDENTES de propósito, para aceitar ao vivo). Ferramentas em `connect-ong-api/ferramentas/`.
> **Última rodada (12/08):** o banco cheio revelou três problemas de TELA, todos fechados — carrossel de campanhas estourando a largura, campanha sem caminho para o perfil da ONG e o mapa da web ilegível (agora em 3 níveis: estado → área → ONG). Ver [ajustes pós-recheio](connect-ong-ajustes-pos-recheio-2026-08-12.md), que também traz **como subir os 4 serviços locais** para conferir na tela.
> **🔑 FRASE-CHAVE COMBINADA:** ao ouvir **"vamos se preparar para a feira no computador de apresentação"**, executar **`PREPARAR-FEIRA.md`** (raiz do repo mobile) — tudo local no notebook. Ainda NÃO executado.
> **🔴 A lentidão NÃO é o código nem o volume: é o Render grátis.** Mesma tela, mesmo banco: perfil de ONG 4,85s no Render × **0,81s local**. Ver [massa-demo + feira](connect-ong-massa-demo-e-feira-2026-08-11.md).
> **Testes:** backend **179** · doador **98** · painel **50**.
> **🌐 No ar:** site https://connectong.netlify.app · doador https://gabriel-chinelatto.github.io/connect-ong/ · painel https://gabriel-chinelatto.github.io/connect-ong-desktop/ · API https://connect-ong-api.onrender.com + MySQL da escola. `git push` = deploy automático. **Os 4 repos são PÚBLICOS (nunca commitar segredo).**
> **⏰ A API hiberna** (~15 min ociosa; 1ª chamada de 10 a 95s): acordar antes de qualquer apresentação. Se ela CAIR, ler Events/Logs no Render antes de supor hibernação (a causa real já foi estouro de 512 MB).
> **📋 Apresentar:** `COMO-MOSTRAR.md` (repo mobile). Contas: `demo.joao@connectong.com` / `demo.larviva@connectong.com`, senha `demo123`.
> **⚠️ Nome "web":** o portal que o usuário chama de web **é o app mobile no navegador** (`lib/web/portal_institucional_screen.dart`, repo `connect-ong`). O site em HTML puro é outro repo (`connect-ong-web`).
> **🔴 PENDÊNCIA HUMANA: rotacionar a senha do MySQL** (está no histórico do GitHub público; o banco aceita qualquer host). Passo a passo em `C:\Users\01gabriel.MAQCHINELATTO\CONNECT-ONG-SEGREDOS.txt`.
> **⏭️ Aguardando o usuário:** (1) se a feira terá internet — decide se vale cachear as imagens do mapa; (2) escolher as **fotos reais** (guia pronto em `connect-ong-api/ferramentas/COMO-COLOCAR-FOTOS.md`, script faz o resto); (3) dizer a frase-chave quando quiser preparar o notebook; (4) rotacionar a senha do MySQL; (5) UptimeRobot; (6) apagar a pasta solta `connect-ong/connect-ong-web/` (já está no .gitignore, mas continua no disco).

- [Preparação da feira (2026-08-13)](connect-ong-preparacao-feira-2026-08-13.md) — **máquina de apresentação PRONTA e testada**: MySQL 8 portátil (sem admin) com o banco da escola importado, jar + builds release + APK, scripts de 1 clique (INICIAR/PARAR/RECOMPILAR/ATUALIZAR-BANCO), mapa offline por cache de tiles no serve.py, aquecimento automático. Gotchas novos: **CA do Avast rotaciona**, `findstr` com espaço vira OU, `timeout` do Git Bash sombreia o do Windows.

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
