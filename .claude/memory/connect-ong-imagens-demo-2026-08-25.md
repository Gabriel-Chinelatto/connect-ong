---
name: connect-ong-imagens-demo-2026-08-25
description: "Ilustracao da demonstracao inteira (logo + capa nas 2.000 ONGs, retrato nos 1.200 doadores): a coluna ong.logo_base64, os endpoints de imagem por URL que evitaram a listagem virar 80 MB, o RESTAURAR-DEMO que apagava as fotos e a marca d'agua do rawpixel"
metadata:
  node_type: memory
  type: project
---

# Imagens em toda a demonstracao — 25/08/2026 (6 dias p/ a FECITEC)

O usuario pediu: conferir mobile+emulador e **por imagem em TODAS as ONGs**
(logo + fundo coerentes com a causa) e **foto de perfil em todos os doadores**.
Ate aqui so 6 das 2.000 ONGs tinham capa (ver
[[connect-ong-conferencia-final-2026-08-24]]).

## O que foi feito

- **2.000 ONGs com logo + capa** e **1.200 doadores com retrato**, no banco
  LOCAL da feira. A imagem sai da **causa** de cada ONG (11 causas).
- **`ong.logo_base64`** (changeset `feira-ong-logo-base64`) — a "foto de perfil"
  do circulo do cabecalho. Exposta no perfil publico e no GET /ongs/{id};
  aceita no PUT (null = mantem, mesma regra da capa). O painel da ONG ganhou
  "Logo da ONG" no Editar perfil (com guarda de alteracoes nao salvas).
- **`ferramentas/ilustrar_demo.py`** (backend) aplica tudo e gera o `.sql`.
  Scripts que criam as imagens: `ferramentas/imagens/` + `CREDITOS.md`.
- Arquivos da feira: `FEIRA ESCOLA\interno\imagens-demo\` (48 capas, 44 logos,
  198 retratos, 6 capas curadas) e `interno\fotos-demo.sql` (5 MB).
- Novo `RECOMPILAR-APK.bat` (o APK levava ~8 min e nao estava em script nenhum).

## 🔴 A descoberta que mudou o desenho: a listagem carrega base64

`GET /ongs` devolve **TODAS as ONGs numa resposta so** (2.000, sem paginacao) e
mandava `capaBase64` de cada uma. Com 6 capas isso eram 2,43 MB. Com as 2.000
ilustradas seriam **~80 MB por chamada** — o app simplesmente nao abriria.

Correcao: a listagem **deixou de mandar base64** e as imagens dos CARDS passam
a ser buscadas por URL, uma a uma e so quando o card aparece na tela:

    GET /publico/ongs/{id}/logo     GET /publico/ongs/{id}/capa

(`ImagemOngService`, publicos porque uma `<img>` nao manda header
Authorization; `Cache-Control` de 12 h.) Medido: a listagem **encolheu** de
2,43 MB para **1,29 MB** mesmo com as 2.000 ONGs ilustradas. O perfil detalhado
continua com base64 embutido (uma ONG por vez).

No front isso virou `LogoOng` (Flutter) e `UI.avatarOngUrl` (web): a inicial do
nome fica desenhada embaixo e a `<img>` some sozinha no 404 — nao e preciso
saber de antemao quem tem logo, e nunca aparece icone de imagem quebrada.

## 🐛 O RESTAURAR-DEMO apagava as fotos (bug que ninguem tinha visto)

Em 24/08 o `ATUALIZAR-BANCO` foi ensinado a re-aplicar as fotos, mas o
**`RESTAURAR-DEMO` nao** — e ele reimporta o MESMO dump da escola, que vem sem
imagem nenhuma. Ou seja: as fotos das 6 ONGs sumiriam na **primeira** vez que o
usuario apertasse "voltar ao inicio" entre duas apresentacoes.

Corrigido: os dois .bat agora rodam `interno\fotos-demo.sql` depois do dump.
Esse arquivo **agrupa** as ONGs que dividem a mesma imagem
(`UPDATE ... WHERE id IN (...)`): 286 comandos no lugar de 5.206, 5 MB no lugar
de ~150 MB. Ele tambem **recria a coluna `logo_base64`** quando falta (o dump da
escola e anterior a ela; como o MySQL nao tem `ADD COLUMN IF NOT EXISTS`, usa
`information_schema` + `PREPARE`), e roda numa transacao so.

⚠️ **O RESTAURAR-DEMO passou de ~15 s para ~50 s** (12 s do dump + ~35 s de
imagens). Sao ~80 MB gravados; nao da para acelerar muito. Esta escrito no .bat
e no COMO-MOSTRAR.

## 🐛 Marca d'agua do rawpixel

O Openverse mistura fontes. As imagens do **rawpixel** vem com "rawpixel"
**ladrilhado por cima** — invisivel na miniatura da folha de contato, obvio no
cabecalho do perfil (descobri olhando a tela do emulador). Eram **18 das 54**
capas. Refiz as buscas com `excluded_source=rawpixel`. Hoje: 47 wikimedia +
2 stocksnap, zero rawpixel.

## 🐛 A heuristica de causa erra por PEDACO de palavra

`seed_demo.causa_por_nome` procura substring solta. Resultado: "**Aca**o Social
Bom Pastor" e "Funda**cao** Tecnologia Social" caiam em ANIMAIS (o "cao" de
"acao") e "Instituto Bem-Estar Comunita**rio**" em AMBIENTE (o "rio") — ganhava
capa de plantio de arvore.

`ilustrar_demo.causa_da_ong` resolve em tres niveis: (1) as 10 ONGs antigas
cadastradas a mao tem a causa escrita a mao no dicionario `CAUSA_A_MAO`,
conferida na descricao; (2) o **nucleo do nome** ("Lar Viva", "Abrigo Patinhas",
"Semente do Amanha" — o seed monta todo nome a partir de um nucleo da causa),
que classifica 1.990 de 2.000 com exatidao; (3) so no resto, a heuristica antiga.
Prova de que ficou certo: a distribuicao entre as 11 causas ficou plana
(161 a 215 por causa).

## De onde vem cada imagem

| | Origem | Direito |
|---|---|---|
| Logo (44) | **Autoral**: disco na cor da causa + pictograma Material Icons (Apache 2.0, ja vem com o Flutter), gerado por `gerar_logos.py` | sem restricao |
| Capa (48) | Wikimedia/Openverse, licenca livre, recortadas 16:9 e comprimidas com teto de 38 KB | CC BY / CC0 |
| Doador (198) | randomuser.me, escolhido pelo **sexo do primeiro nome** | uso nao comercial (e o caso) |

Peso: capa ~35 KB (720px, qualidade adaptativa), logo ~4 KB (PNG chapado de 32
cores), retrato ~5 KB. Total no banco: ~80 MB.

## Pegadinhas do caminho

- **data-URI x base64 puro:** o painel grava base64 **puro**; os scripts gravam
  **data-URI**. O `base64Decode` do Dart estoura com data-URI e o `catch` engolia
  — a imagem sumia **sem erro na tela**. Era assim desde 24/08 com as 6 capas no
  mobile. Os tres frontends agora aceitam os dois formatos.
- **Emulador:** compilar o APK e rodar o emulador ao mesmo tempo trava o Android
  com ANR do `system`/`systemui`. Feche os builds antes. O `adb reverse tcp:8080`
  precisa ser refeito a cada reinicio do emulador.
- **Commons bloqueia rajada:** `upload.wikimedia.org` responde 429 com 10 threads;
  3 threads + repeticao resolve.
- **`GET /ongs` exige token** e o login e `POST /usuarios/login` (nao `/auth/login`).

## Conferido ao vivo

- Emulador (APK novo, `adb reverse`, backend local): login, feed, detalhe da
  necessidade com o logo no cartao da ONG e perfil da ONG com logo + capa.
- Web (headless): cards com capa `lazy` e logo por URL.
- API: `/publico/ongs/33/logo` 200 image/png 4 KB em 0,04 s; perfil de ONG
  generica 80 KB em 0,055 s; listagem 1,29 MB em 0,4 s.
- Testes: backend **191**, doador **101**, painel **52** — todos verdes.
- Artefatos reconstruidos: jar, doador web, painel web (agora com
  `--pwa-strategy=none`) e APK do emulador.

## O que NAO foi feito (de proposito)

- **Producao intocada**: as imagens estao so no banco local, mantendo a decisao
  de 24/08. Para levar ao site publicado: rodar `ilustrar_demo.py` sem `--host`
  (vai para o banco da escola) — sao ~80 MB no MySQL da escola, avaliar antes.
- ⚠️ O **push do backend deploia no Render**, e o Liquibase vai **criar a coluna
  `logo_base64` no banco da escola** no proximo start. E aditiva e nullable
  (nada quebra), mas e uma mudanca de schema em producao: fica registrado aqui.
