---
name: connect-ong-notebook-fecitec
description: "Setup do NOTEBOOK de apresentacao da FECITEC (usuario Windows 'gabri') — caminhos, toolchain e como subir os 3 frontends nesta maquina"
metadata:
  node_type: memory
  type: project
  originSessionId: 29811329-d22b-44a3-85f0-3e1c2637d9eb
---

Existe um SEGUNDO computador (alem da maquina da escola `01gabriel.MAQCHINELATTO` descrita em [[connect-ong-architecture]]): o **notebook pessoal do usuario `gabri`**, que sera **LEVADO PARA A FECITEC** para a apresentacao. Configurado em 2026-06-26. Caminhos nesta maquina:

- **Mobile (doador)**: `C:\Users\gabri\Desktop\connect-ong` (branch main) — este e o repo que contem `.claude/memory/` (as memorias sincronizam via git aqui).
- **Desktop (painel ONG)**: `C:\Users\gabri\Desktop\connect-ong-desktop` (branch main).
- **Backend**: raiz Maven em `C:\Users\gabri\IdeaProjects\connect-ong-api\API - Chinelatto - att2\API - Chinelatto\API - Chinelatto` (branch master).

**Toolchain instalado/configurado nesta maquina:**
- **JDK = Amazon Corretto 21** em `C:\Users\gabri\.jdks\corretto-21.0.3` (o JDK 8 que estava no PATH NAO serve p/ Spring Boot 3.5/Java 17). `JAVA_HOME` (User) corrigido p/ apontar p/ o Corretto 21 (antes apontava p/ `jdk-22` inexistente).
- **Maven 3.9.11** instalado de forma permanente em `C:\Users\gabri\tools\apache-maven-3.9.11` (+ no PATH/MAVEN_HOME). NAO usar o `./mvnw` do projeto: o wrapper baixa o Maven via curl e falha pela interceptacao TLS do Avast (ver [[ambiente-java-avast-tls]]).
- **Android SDK** PRONTO em `C:\Users\gabri\AppData\Local\Android\Sdk`: cmdline-tools, platform-tools, emulator, **platforms;android-36 + build-tools;36.0.0** (Flutter 3.44 exige API 36 p/ compilar, NAO 35), system-image `android-35;google_apis;x86_64`. **AVD `ConnectOng`** (pixel_6) criado, licencas aceitas, `flutter doctor` Android = VERDE. **Android Studio** em `C:\Program Files\Android\Android Studio`. Virtualizacao OK (Hyper-V/VBS ativo → emulador usa WHPX).
- **Flutter 3.44.1** em `C:\flutter`. Devices: Windows, Chrome, Edge.
- **Visual Studio Community 2022 JA instalado**, mas FALTA o workload "Desktop development with C++" → por isso o build Windows nativo falha ("Unable to find suitable Visual Studio toolchain"). Decisao do usuario (2026-06-26): deixar o desktop NATIVO p/ depois; por enquanto rodar no Chrome.

**Como subir os 3 frontends nesta maquina (forma testada 2026-06-26):**
1. Backend: `JAVA_HOME=...corretto-21.0.3` + `mvn spring-boot:run` na raiz Maven → porta 8080 (conecta no MySQL 5.6 da escola; dados demo ja semeados no banco remoto compartilhado).
2. Painel ONG: `cd connect-ong-desktop && flutter run -d chrome --web-port=5599` (baseUrl ja = localhost:8080).
3. App doador: `cd connect-ong && flutter run -d chrome --web-port=5601` (no Chrome abre o PORTAL por `kIsWeb` → botao "Entrar" leva ao login).
- **Scripts prontos** em `C:\Users\gabri\Desktop\INICIAR-FECITEC\` (1-backend.bat, 2/3 apps, LEIA-ME.txt). NAO versionados (caminhos sao especificos desta maquina, como o settings.local.json).

**Mobile no EMULADOR:** o script `4-app-doador-emulador.bat` sobe o AVD, faz `adb reverse tcp:8080 tcp:8080` e roda o app — assim a `baseUrl` continua `http://localhost:8080` (SEM precisar trocar p/ 10.0.2.2). So nao testei o boot real do emulador ainda (deixado pronto; usuario parou a sessao).

**RISCO #1 DA FECITEC (decisao do usuario = confiar no MySQL da escola, sem banco local):** o app depende do MySQL remoto `143.106.241.3:3306`. Testar o login LOGO ao chegar no evento; se a rede da FECITEC nao alcancar esse IP, nada funciona. Plano B (nao adotado) seria um MySQL local. **LEMBRAR o usuario disso perto da data.**

Contas demo (senha `demo123`): ONG `demo.larviva@connectong.com` (id 14, ongId 33), doador `demo.joao@connectong.com` (id 18). Ver [[connect-ong-architecture]] e [[git-workflow-preferences]].

**Sincronizar com 1 clique (feito 2026-07-02):** `sincronizar.bat` na raiz do repo mobile — clicar puxa e envia os 3 repos (descobre os caminhos sob `%USERPROFILE%`, funciona nos 2 PCs). ANTI-REGRESSAO: pull `--rebase --autostash` (em conflito faz `rebase --abort` e restaura, nunca reverte/perde trabalho) e **so faz push se a verificacao passar** (Flutter `flutter analyze` limpo; backend compila) — build quebrado nunca chega ao outro PC (comprovado). Tambem existe a skill `/sincronizar` (pedir "sincronizar" no chat faz o mesmo). `.gitattributes` forca CRLF nos `.bat`. Commits: `68e0413`/`3107106`.

**Modo Feira (feito 2026-07-02, mobile `4d22d56`, desktop `cc00ffd`):** com o "Modo Feira" ligado (default true, flag local em SharedPreferences), a tela de login mostra um card com as credenciais demo (mobile = doador `demo.joao@connectong.com`; desktop = ONG `demo.larviva@connectong.com`; senha `demo123`) + botao "Preencher". Toggle nas Configuracoes de cada app desliga o card. Serve p/ nao anotar login em papel na feira. NOTA: essa flag local do FRONTEND (card de credenciais) e DIFERENTE do `app.demo.enabled` do BACKEND (proximo paragrafo) — nao confundir.

**⚠️ AÇÃO NOVA DA FEIRA — `APP_DEMO_ENABLED=true` no BACKEND (mudou em 2026-07-10):** o quick win da auditoria inverteu o default do `app.demo.enabled` do backend p/ `false` (era `true`) por segurança — com ele OFF, o `codigoDemo` do esqueci-senha e do 2FA NAO volta no JSON. Como a demo da feira usa esse código na tela, **nesta máquina é OBRIGATÓRIO ligar**: adicionar `set APP_DEMO_ENABLED=true` no `1-backend.bat` (antes do `mvn spring-boot:run`) OU pôr `app.demo.enabled=true` no `application-local.properties` do backend. Sem isso o fluxo de recuperar senha/2FA quebra na apresentação. Ver [[connect-ong-auditoria-final]].

**Sincronizacao Claude Code entre os 2 PCs (feito 2026-07-02, commit mobile `25f4b8f`; ver `.claude/README-SYNC.md`):** o que sincroniza pelo git (dentro do repo mobile `connect-ong/.claude/`): `memory/` (ja era), `settings.json` (agora portavel — tirado o caminho absoluto de maquina) e `skills/fable5/` (antes so no `~/.claude` de um PC, agora dentro do projeto). O que e por-maquina (gitignored): `settings.local.json` — cada PC copia do `settings.local.json.example` e troca `SEU_USUARIO` (aqui no notebook = `gabri`) para preencher o modo de permissao + os caminhos dos outros 2 repos. Regra pratica: **abrir o Claude Code a partir do repo mobile** (ancora memoria+skill) com backend/desktop como `additionalDirectories`. Editar a skill fable5 sempre a do PROJETO (a copia em `~/.claude/skills` de cada PC e secundaria).
