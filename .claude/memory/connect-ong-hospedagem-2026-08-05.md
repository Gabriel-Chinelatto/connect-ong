---
name: connect-ong-hospedagem-2026-08-05
description: Os 3 frontends publicados (Netlify + GitHub Pages), a causa REAL das quedas da API (estouro de 512MB no Render) e como apresentar sem depender da maquina do desenvolvedor
metadata:
  type: project
---

# Hospedagem e quedas da API — 2026-08-05

## 🔴 A causa real das quedas: MEMORIA, nao hibernacao

O painel de eventos do Render entregou o diagnostico que faltava:

```
04/08  "Exited with status 1"  -> servico caiu, 502 em 100% das chamadas
05/08  10:40  Deploy FAILED — "Ran out of memory (used over 512MB)"
```

O `Dockerfile` rodava **`java -jar app.jar` sem nenhum limite**. Sem parametros a
JVM decide sozinha e a soma (heap + metaspace + cache de codigo + pilha de cada
thread do Tomcat) passa dos 512 MB do plano gratuito — o Render entao mata o
processo. Isso vinha sendo confundido com "hibernacao" e com "o Render as vezes
cai".

**Correcao (commit `1e3e5e7`):**
- Dockerfile: `MaxRAMPercentage=50` (heap ≤ ~256MB; o padrao da JVM so enxerga o
  heap e ignora o resto), `MaxMetaspaceSize=128m`, `UseSerialGC` (o G1 mantem
  estruturas que nao se pagam em heap pequeno), `Xss512k`, `TieredStopAtLevel=1`.
- `application.properties`: Tomcat de **200 para 25 threads**
  (`APP_TOMCAT_THREADS`) — cada thread reserva pilha propria.

**Medido antes de subir**, rodando o JAR com `-XX:MaxRAM=512m` para simular o
Render: sobe normal, responde em 0,02s, usa **271 MB** e fica em **275 MB**
depois de 75 requisicoes. Folga de ~46%.

⚠️ Se voltar a cair, olhar **Events/Logs no Render** primeiro — a mensagem diz
exatamente o que houve. Nao presumir hibernacao.

## 🌐 Os 3 frontends agora abrem em QUALQUER maquina

| App | Endereco |
|---|---|
| Site do doador (HTML puro) | https://connectong.netlify.app |
| App do doador (Flutter web) | https://gabriel-chinelatto.github.io/connect-ong/ |
| Painel da ONG (Flutter web) | https://gabriel-chinelatto.github.io/connect-ong-desktop/ |

Os dois novos publicam sozinhos via `.github/workflows/publicar-web.yml` a cada
push na `main` (roda `analyze` + testes antes; so publica se passar).

**Pegadinhas que custaram tempo e vao se repetir:**
- O GitHub Pages precisa ser **habilitado na mao** em *Settings > Pages >
  Source: GitHub Actions*. O `enablement: true` do `configure-pages` **nao
  funcionou** (exige permissao de dono). Sem isso o job falha so nesse passo.
- `--base-href /nome-do-repo/` e obrigatorio (o Pages serve em subpasta); sem
  ele o app abre **em branco**.
- O dominio `https://gabriel-chinelatto.github.io` precisa estar no **CORS** do
  backend (`SecurityConfig.allowedOrigins`, commit `b3543ef`) — senao o app
  carrega mas nao busca dado nenhum.
- A aba do navegador mostrava `flutter_application_1` / `connect_ong` (nome do
  template). Corrigido em `web/index.html` + `web/manifest.json`.

## 🔑 Modo Feira: ligado local, DESLIGADO no que e publicado

`ConfigController` passou a ler o padrao do build:
`bool.fromEnvironment('MODO_FEIRA_PADRAO', defaultValue: true)`.

- **Build local / emulador / feira:** continua ligado — credenciais aparecem na
  tela, como sempre foi.
- **Versao publicada:** compilada com `false`. Antes, qualquer pessoa que
  abrisse o link veria e-mail e senha validos; **confirmado que a conta
  `demo.larviva@connectong.com`/`demo123` responde 200 na API de producao**,
  entao daria para entrar e alterar os dados da demonstracao.

Contas (anotar, nao aparecem mais na tela publica):
`demo.joao@connectong.com` / `demo123` (doador) ·
`demo.larviva@connectong.com` / `demo123` (ONG).

## 📋 Apresentacao

O guia esta versionado em **`COMO-MOSTRAR.md`** (raiz do repo mobile): links,
como acordar a API antes, contas demo, plano B local e o que fazer se falhar.

- **PC da escola / demonstracao ao grupo:** so navegador. Nao precisa IntelliJ,
  nao precisa clonar, nao precisa instalar nada.
- **FEIRA (decidido pelo usuario):** vai ser no **emulador Android do notebook**
  dele — ainda a configurar, "mais perto da feira". No emulador, `localhost` e o
  proprio celular virtual: para backend local usar
  `--dart-define=API_BASE=http://10.0.2.2:8080`. Com a API na nuvem funciona sem
  parametro. Sugerido tambem gerar **APK** (`flutter build apk --release`) e usar
  o celular real como principal, com o emulador de reserva.
- Esta maquina (`01gabriel.MAQCHINELATTO`) **nao tem Android SDK** — APK e
  emulador so no notebook. Cuidado com o **Avast/PKIX** ao baixar componentes
  (ver [[ambiente-java-avast-tls]]).

## ⏰ Hibernacao: o ping por GitHub Actions NAO resolve

`manter-api-acordada.yml` (repo da API) foi criado para pingar a cada 10 min,
mas o GitHub **descarta a maioria dos agendamentos curtos**: em 21h rodou **12
vezes** (~1 a cada 2h). Como anti-hibernacao **nao serve**; continua util como
**alarme** (falha => e-mail quando a API esta fora). Para resolver de verdade
precisaria de servico externo (UptimeRobot/cron-job.org) — exige cadastro do
usuario, ainda nao feito.

Na pratica: **abrir qualquer link ~2 min antes de apresentar** para acordar.

Ver [[connect-ong-feedback-app-2026-08-03]] (timeout adaptativo e repeticao das
leituras, que tornam essas falhas menos visiveis) e [[connect-ong-architecture]].
