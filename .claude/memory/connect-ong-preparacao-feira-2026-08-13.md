---
name: connect-ong-preparacao-feira-2026-08-13
description: "PREPARAR-FEIRA.md EXECUTADO em 13/08/2026 no notebook gabri: MySQL portatil local + jar + builds release + APK + scripts de 1 clique; telas de 4,85s cairam para ~0,1-0,4s; como manter/refazer cada peca"
metadata:
  node_type: memory
  type: project
originSessionId: 55296eb6-8279-4787-a454-d6bfcfaa4661
---

# Preparacao da maquina de apresentacao — EXECUTADA em 13/08/2026

O usuario disse a frase-chave no notebook `gabri` (ver [[connect-ong-notebook-fecitec]])
e o plano `PREPARAR-FEIRA.md` foi executado INTEIRO no mesmo dia, sem precisar
dele para nada (nem senha de admin: o MySQL foi instalado PORTATIL, sem MSI).

## O que ficou pronto (tudo TESTADO de ponta a ponta)

**Na Area de Trabalho (fora de repo, caminhos desta maquina):**
- `INICIAR-FEIRA.bat` — 1 clique: sobe MySQL local + API (jar) + doador (5000)
  + painel (5001) + site (8090), espera a API, RODA O AQUECIMENTO sozinho e abre
  as 3 abas. Pronto em ~40s. Idempotente (checa cada porta antes de subir).
- `PARAR-FEIRA.bat` — derruba tudo (MySQL com shutdown limpo via mysqladmin).
- `RECOMPILAR-FEIRA.bat` — depois de mexer no codigo: rebuilda jar + 2 builds
  web (~5 min). Resposta a pergunta do usuario "consigo alterar algo depois?": SIM.
- `ATUALIZAR-BANCO-DA-ESCOLA.bat` — recopia o banco remoto p/ o local (~1 min);
  rodar na VESPERA da feira para levar dados frescos.
- `LEIA-ME-FEIRA.txt` — guia do dia. `C:\Users\gabri\Desktop\FEIRA-LOCAL\` tem
  `ConnectONG.apk`, `aquecer.py`, o dump `banco-escola.sql` e logs.

**Medido (aquecido, banco local):** login 0,10s · ranking 0,15-0,17s · perfil
ONG 0,10-0,23s · feed 0,38-0,59s · lista ONGs 0,13s. No Render eram 1,4-6,6s e
o ranking estourava timeout. Aquecimento importa: 1o hit de cada rota e 2-6x
mais lento (JIT); o `aquecer.py` roda no fim do INICIAR-FEIRA.bat sozinho.

## As pecas (como refazer cada uma)

1. **MySQL 8.0.43 PORTATIL** em `C:\Users\gabri\tools\mysql` (zip, sem admin,
   sem servico) + dados em `tools\mysql-data` + config `tools\mysql\my-feira.ini`
   (porta 3306 so em 127.0.0.1; `sql_mode=NO_ENGINE_SUBSTITUTION` p/ aceitar o
   dump do 5.6; `max_allowed_packet=256M` p/ fotos base64). Root local SEM senha
   (loopback apenas); app usa usuario `feira`/`feira123`.
   ⚠️ NAO usar `skip-name-resolve`: com ele, `root@localhost` nao casa com
   conexoes TCP de 127.0.0.1 e NADA loga.
2. **Copia do banco da escola**: `mysqldump` do 8.0 contra o 5.6 remoto funciona
   com `--column-statistics=0 --set-gtid-purged=OFF --single-transaction
   --skip-lock-tables --no-tablespaces`. 12 MB, importa em 10s. Numeros conferem
   com [[connect-ong-massa-demo-e-feira-2026-08-11]] (2.000/1.211/7.075).
   Liquibase validou o schema importado sem reclamar.
3. **Backend**: `mvn -DskipTests package` → jar unico. O bat roda `java -jar`
   com env `DB_URL=jdbc:mysql://127.0.0.1:3306/cl203161?useSSL=false&
   allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo`,
   `DB_USERNAME=feira`, `DB_PASSWORD=feira123`, `APP_DEMO_ENABLED=true`,
   perfil `local` (JWT secret continua vindo do application-local.properties;
   env sobrepoe arquivo no Spring). Sobe em ~20s.
4. **Frontends**: `flutter build web --release --dart-define=API_BASE=
   http://127.0.0.1:8080` nos 2 repos; servidos por `python -m http.server`
   (5000/5001, bind 127.0.0.1). Site pelo `serve.py` (8090). Modo Feira fica ON
   sozinho em build local (so o publicado passa MODO_FEIRA_PADRAO=false).
   Python 3.12 instalado por winget (`--source winget` — a fonte msstore falha
   com o Avast) em `%LOCALAPPDATA%\Programs\Python\Python312`.
5. **Mapa OFFLINE** (repo web, commit `b8e4bae`): `serve.py` ganhou a rota
   `/tiles/{z}/{x}/{y}.png` com cache em `tiles-cache/` (gitignored) e fallback
   PNG transparente; `app.js` usa essa rota SO quando `location.hostname` e
   local (site publicado inalterado). `baixar_tiles.py` pre-carrega Brasil z4-7
   + Limeira/Campinas z8-13 (~1.300 tiles, ~15 MB). Sem internet o mapa funciona.
6. **APK** (58,5 MB): `flutter build apk --release` SEM dart-define → aponta p/
   o Render (celular usa a propria internet). Copia em FEIRA-LOCAL\ConnectONG.apk.
   Falta so instalar no celular (cabo USB, unico passo humano restante).

## Gotchas que custaram tempo (nao repetir)

- **A CA do Avast ROTACIONOU** desde 26/06: o cacerts tinha a CA antiga
  (SHA1 FF:52...) e o Windows ja usava outra (FE:C5...) → PKIX de novo no
  Gradle, mesmo com JAVA_HOME certo. Fix: reexportar do
  `Cert:\LocalMachine\Root` e importar com alias novo (`avast-root-2026-08`).
  Detalhe: o Gradle usava o JBR do Android Studio, nao o Corretto —
  `flutter config --jdk-dir=C:\Users\gabri\.jdks\corretto-21.0.3` resolve
  permanente. Atualizado em [[ambiente-java-avast-tls]].
- **`findstr` com espaco no padrao vira OU**: `findstr /r ":8080 .*LISTENING"`
  casa com QUALQUER linha LISTENING (o MySQL sempre esta ouvindo) → o bat achava
  que a API "ja estava no ar" e nao subia nada. Fix: dois findstr encadeados com
  `/c:` literal. Nos .bat tambem troquei `timeout /t` por `ping -n N 127.0.0.1`
  (o GNU timeout do Git Bash sombreia o do Windows quando lancado dali).
- `.bat` novos: gravar e converter p/ CRLF (unix2dos) antes de rodar.

## Estado / proximos passos

- [x] Tudo local, rapido, aquecido, testado (screenshots das 3 telas OK).
- [ ] Instalar `ConnectONG.apk` no celular do usuario (precisa do cabo).
- [ ] Vespera da feira: rodar `ATUALIZAR-BANCO-DA-ESCOLA.bat` (dados frescos)
      e conferir `INICIAR-FEIRA.bat` 1x.
- [ ] Pendencias humanas antigas: fotos reais, rotacao da senha do MySQL.
- Plano B continua sendo os links publicados (Render/Netlify/Pages).
