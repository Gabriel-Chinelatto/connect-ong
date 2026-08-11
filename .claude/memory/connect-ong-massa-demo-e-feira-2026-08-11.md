---
name: connect-ong-massa-demo-e-feira-2026-08-11
description: "Recheio do banco para a apresentacao (2.000 ONGs pelo Brasil, contas da feira com historico escrito a mao), o N+1 que travava o ranking, e o PLANO DA MAQUINA DE APRESENTACAO que so roda quando o usuario disser a frase-chave"
metadata: 
  node_type: memory
  type: project
  originSessionId: 01999f4b-11a0-40ba-a799-57d84627ae96
  modified: 2026-08-11T14:51:10.607Z
---

# Rodada de 11/08/2026 — massa de demonstracao + plano da feira

## 🔑 FRASE-CHAVE COMBINADA (gatilho, ainda NAO executado)

Quando o usuario disser **"vamos se preparar para a feira no computador de
apresentacao"** (ou equivalente claro), executar o plano de
**`PREPARAR-FEIRA.md`**, na raiz do repo mobile `connect-ong`. Ele ja esta
escrito, medido e commitado — e so seguir os 10 passos.

Resumo do plano: levar TUDO para o notebook (MySQL local + backend local +
frontends locais + APK no celular), com um atalho unico que sobe tudo e um
script de aquecimento. Precisa do usuario em dois pontos: instalar o MySQL
(senha de administrador) e plugar o celular para o APK. Ele ainda **nao
respondeu se a feira tera internet** — isso decide se vale cachear as imagens
do mapa (OpenStreetMap) antes.

## 🔴 A descoberta que muda o diagnostico da lentidao

O usuario reclamou da demora ao mostrar para os amigos. Medi as MESMAS telas,
com o MESMO banco da escola e os MESMOS dados, mudando so onde o servidor roda:

| Tela | Render (hoje) | Servidor local |
|---|---|---|
| Feed de necessidades (909 abertas) | 1,43s | **0,16s** |
| Lista de ONGs (2.000, 1,4 MB) | 2,95s | **0,25s** |
| Perfil de uma ONG | 4,85s a 6,65s | **0,81s** |
| Ranking de transparencia | estourava o timeout | **0,36s** |

**Nao e o volume de dados nem o codigo: e o plano gratuito do Render** (1/10 de
CPU, 512 MB, servidor em Oregon com o banco em Campinas — ~150ms por consulta,
e uma tela faz 14). Contei as consultas com `spring.jpa.show-sql` ligado: 14
por perfil, sem N+1. **Nao repetir a suposicao de que "o app esta lento" sem
antes separar servidor de codigo.**

## 🐛 N+1 que so apareceu com o banco cheio (CORRIGIDO, commit `5ff67bc`)

`/publico/ranking` passou de instantaneo para **mais de 180 segundos**.
`TransparenciaService.pendenciasDefinitivasPorOng()` trazia as ENTIDADES
`Interesse` e percorria chamando `i.getNecessidade().getOng().getId()` — duas
consultas por pendencia. Com 2 pendencias no banco antigo, invisivel; com mais
de mil, minutos. Agora `InteresseRepository.pendenciasDefinitivasPorOng(limite)`
agrupa no banco e o corte de 10 dias virou parametro de data. 179 testes verdes.
**Licao: banco de teste vazio esconde N+1; ao recheiar, medir de novo TUDO.**

## O que existe no banco agora

2.000 ONGs · 1.200 doadores · 7.075 necessidades (909 abertas) · 4.633 matches
aceitos · 3.254 prestacoes · 32.318 doacoes PIX (R$ 3,56 mi) · 16 mil mensagens.

- ONGs espalhadas pelas 27 UFs, com peso populacional; **coordenada real do
  municipio** (base IBGE que ja existia em `resources/geo/municipios.json`, que
  tambem tem o DDD — por isso os telefones batem com a cidade).
- As 4 ONGs da feira tem **endereco real geocodificado pelo Nominatim** (ex.:
  Lar Viva na Rua Boa Morte, Limeira) e cache em `dados_demo/cache_enderecos.json`.
- **Contas da feira com historico escrito a mao** (`dados_demo/demo_feira.py`):
  Joao Pereira tem 11 conversas concluidas com prestacao de contas casada com o
  que foi doado; a Lar Viva e a #1 do ranking (score 90, 23 dias no topo) e
  **fica de proposito com 2 interesses PENDENTES**, para aceitar AO VIVO na
  demonstracao, e 3 necessidades ABERTAS, para o doador demonstrar interesse na
  hora.
- Cadastros de teste renomeados (nada apagado, ids preservados): "ONG Teste
  FECITEC" -> Casa de Apoio Amanhecer, "ong do chinelao" -> Instituto Passo
  Solidario, "JWT Teste"/"Audit Teste"/"B17" viraram nomes de pessoa, e
  necessidades como "batata doce"/"chinelos" ganharam texto de verdade.

## Ferramentas (repo `connect-ong-api`, pasta `ferramentas/`)

- `seed_demo.py` — gera tudo. `--dry-run` (gera e desfaz), `--limpar` (remove
  pelo manifesto), `--somente-arrumar`, `--host/--banco` para o banco local da
  feira. **Reproduz o mesmo banco no notebook.**
- `dados_demo/conteudo.py` — vocabulario (11 causas, moldes de descricao,
  roteiros de chat). `demo_feira.py` — as contas da feira.
- `subir_fotos.py` + `COMO-COLOCAR-FOTOS.md` — o usuario poe as fotos numa pasta
  (`capa/lar-viva.jpg`, `local/`, `prestacao/`) e o script reduz e grava.
  Pendente do lado dele: escolher as fotos (Pexels/Unsplash/Pixabay).
- **Backup antes de tudo:** `C:\Users\01gabriel.MAQCHINELATTO\CONNECT-ONG-BACKUPS\antes-do-recheio-2026-08-11.sql`
  (fora de repo, 626 KB). Gerado por leitura via pymysql — **nao existe
  mysqldump nesta maquina**.

## Armadilhas do banco da escola que vao voltar

1. **As colunas sao latin1** (MySQL 5.6). Acento do portugues funciona e a API
   serve UTF-8 correto (conferido byte a byte), mas **emoji e travessao longo
   quebram** — o seed valida e aborta antes de gravar.
2. **`registrar()` do seed precisa ACUMULAR faixas de id**; sobrescrever fazia o
   `--limpar` apagar so o ultimo id e bater na chave estrangeira.
3. **Numeros que aparecem lado a lado tem que ser coerentes**: a primeira versao
   deixou 1.416 "Conexoes (matches)" com 5.711 "Prestacoes" no mesmo painel do
   portal — impossivel prestar contas de mais entregas do que houve. Corrigido
   mudando a proporcao de status dos interesses. **Conferir o portal antes de
   dar por pronto.**
4. `Ids.novo(tabela, 1)` tem que devolver LISTA (uma ONG com uma unica campanha
   estourava o indice).

## Pendencias do lado do usuario

1. Responder se a **feira tera internet** (mapa/IA/autocomplete).
2. Escolher as **fotos reais** (guia pronto).
3. Rotacionar a senha do MySQL (pendencia antiga).
4. Dizer a frase-chave quando quiser preparar o notebook.

Ver [[connect-ong-varredura-2026-08-10]] e [[connect-ong-hospedagem-2026-08-05]].
