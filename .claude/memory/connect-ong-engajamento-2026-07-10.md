---
name: connect-ong-engajamento-2026-07-10
description: "Rodada de funcionalidades de engajamento (2026-07-10): dias esperando + notificar/reabrir recusa, 'i' + '+X pts' do score da ONG, e foto na avaliacao ONG->doador. Decisoes de escopo do usuario e gotchas (migracao Liquibase, scheduler)."
metadata: 
  node_type: memory
  type: project
  originSessionId: bb82a3ca-9ed8-4018-8831-b0527781da38
---

Terceira leva de melhorias do dia 2026-07-10 (depois dos quick wins e da revisao final de seguranca v1.8 — ver [[connect-ong-auditoria-final]]), pedida pelo usuario como "funcionalidades". Investigada com 3 subagentes read-only antes de codar (mapear o que ja existia p/ nao duplicar). Feita em 2 fases com checkpoints commitados. TODOS os apps analyze limpos; backend 141 testes verdes.

## DECISOES DE ESCOPO DO USUARIO (importantes)
- **SEM sistema de pontos para o DOADOR.** O usuario decidiu que dar pontos ao doador "da sensacao de joguinho". Pontos sao SO da ONG (mais pontos de transparencia = mais visibilidade no ranking, faz sentido). O doador continua so com nota 1-5 (dada pela ONG) + comentarios + fotos. NAO criar gamificacao/placar de doador. (A investigacao confirmou: hoje o doador so tem 4 conquistas booleanas, sem XP/pontos — e assim fica.)
- **"Avaliacao com foto" = a ONG avaliando o DOADOR** (a doacao/produto recebido), NAO o doador avaliando a ONG. Foto SIM, video NAO (base64 de video pesa demais). O usuario topou so foto.

## O QUE JA EXISTIA (nao mexi / reaproveitei)
- ONG **ja** e notificada de novo interesse (tipo MATCH) e **ja** ve o perfil do doador (mas so apos aceitar). Aceite e conclusao **ja** notificavam o doador.
- Backend **ja** reabre interesse apos RECUSADO/CONCLUIDO (nao bloqueia novo interesse). Feed **ja** tem "Demonstrar novamente" para CONCLUIDO.
- Score de transparencia da ONG **ja** era completo (TransparenciaService): verificada +25, notaMedia ate +25, cada prestacao +5 (ate 25), cada campanha concluida +5 (ate 25), −5 por pendencia definitiva (>10 dias sem prestar contas). Niveis Ouro>=75, Prata>=45, Bronze. Ranking so por esse score. Faltava SO a UI explicando isso.

## FASE A (sem mudanca de schema) — commits: backend 13ff81b, + desktop/mobile
- **Dias esperando:** `InteresseResponseDTO.diasEsperando` (calc on-read p/ PENDENTE via ChronoUnit.DAYS de dataCriacao). Desktop mostra "Ha N dias esperando seu aceite" no card PENDENTE (laranja a partir de 10). **`EsperaMatchScheduler`** (@EnableScheduling, novo na app — nao havia scheduler nenhum): job diario (cron `0 0 9 * * *`, configuravel via `app.espera.*`) que notifica a ONG aos 10 dias e depois a cada 5 (10,15,20...). Idempotente pela cadencia diaria (cada interesse cruza um dia-limite uma vez) — SEM coluna de dedupe (evitou migracao). Interesse ganhou setDataCriacao (so p/ testes simularem espera).
- **Recusa:** agora NOTIFICA o doador (`InteresseService.notificarRecusa`, ramo RECUSADO em mudarStatus — antes so ACEITO notificava). Mobile: card "Recusado" (aba Aguardando) ganhou CTA "Demonstrar novamente" (`_reDemonstrar`). Desktop: card PENDENTE ganhou "Ver perfil do doador" (antes so apos aceitar).
- **Sistema de pontos (ONG):** `widgets/common/dialog_pontuacao.dart` (nos 2 apps) = dialogo "Como pontuar" explicando ganho/perda + niveis. Botao "i": desktop na AppBar do painel; mobile na AppBar do perfil publico da ONG. **"+X pts"** nos rotulos das acoes que pontuam (desktop): "Prestar contas (+5 pts)" e "Encerrar (+5 pts)" na campanha.

## FASE B (foto na avaliacao ONG->doador) — commits: backend + desktop + mobile
- **Backend:** nova entidade/tabela **AvaliacaoDoadorFoto** (padrao de PrestacaoFoto: id, avaliacao_doador_id, foto MEDIUMTEXT, criado_em) + repositorio. **Liquibase:** changeset `avaliacao-doador-foto-create-table` (+ indice) no fim de `db.changelog-master.yaml`, idempotente (`not tableExists`). DTOs: `fotos` (req max 3, tamanho por foto <=2.9M no service; resp lista). Service faz upsert das fotos (null=nao mexe) e carrega a listagem publica em 1 query (sem N+1).
- **Desktop:** `DialogAvaliarDoador` ganhou seletor de fotos (max 3, reusa `escolherImagem`/`ImagemSelecionada`); pre-carrega as fotos existentes ao editar (decodifica base64) para nao perde-las; envia o conjunto. Perfil do doador (desktop e mobile) exibe as fotos da avaliacao (miniatura -> ampliar).
- **Mobile:** model `AvaliacaoDoador.fotos`; secao "O que as ONGs dizem" mostra as fotos.

## ⚠️ GOTCHA / ACAO DE VERIFICACAO (feira)
A tabela `avaliacao_doador_foto` **so existe em producao apos a migracao Liquibase rodar no 1o startup** (em teste vem do ddl-auto=create-drop do H2, entao os 141 testes NAO provam o MySQL real). Como o MySQL da escola e 5.6 e nao da p/ testar aqui, **conferir no 1o boot na feira** que a app subiu (Liquibase criou a tabela; se `ddl-auto=validate` reclamar, a migracao falhou). O changeset e padrao (mesmo estilo dos createTable ja existentes que rodam la), risco baixo. Ver [[connect-ong-notebook-fecitec]].

## OBS
A avaliacao ja exigia match CONCLUIDO (feature "avaliacao com lastro" da revisao de seguranca) — a foto so reforca isso. Nao criei scheduler de push local no celular (o "dias esperando" vai p/ a central de notificacoes in-app; push nativo ficou de fora p/ nao adicionar plugin/risco perto da feira).

## RODADA DE FEEDBACK (mesmo dia, apos o usuario ver ao vivo) — 5 ajustes
Verificado ao vivo (backend no MySQL REAL da escola — a migracao Liquibase da foto rodou com sucesso no MySQL 5.6, risco de feira ELIMINADO). Ajustes pedidos, todos commitados/pushados, apps analyze limpos, backend 141 verdes:
1. **Mobile "Aguardando":** o "dias esperando" era so no painel da ONG; o usuario queria no APP DO DOADOR. Agora o card da aba Aguardando mostra "Esperando ha N dias" e a lista ordena por dataCriacao desc (mais recente no topo). models/interesse (mobile) ganhou dataCriacao + diasEsperando.
2. **Backend `Interesse.dataStatus`** (LocalDateTime, migracao addColumn data_status): data da ultima mudanca de status (aceite/recusa/conclusao), exposta no DTO. Base das datas no painel.
3. **Painel ONG — Interesses reorganizado:** estava tudo junto (ativo/recusado/concluido) e o contador somava tudo. Agora ha SUB-ABAS (SegmentedButton) Ativos / Recusados / Concluidos; o contador da aba e do stat card conta so ATIVOS (pendentes+aceitos). Agrupamento por doador + "Ver perfil" mantidos em todas. Cada card mostra DATAS: inicio (criacao), "aceito em", "recusado em <data+hora>", concluido = "inicio + concluido em".
4. **Painel ONG — AppBar agrupada:** os ~10 icones do topo viraram 3 menus PopupMenuButton (Perfil / Transparencia e relatorios / Conta) + o sino. Helper `_menuItem`.
5. **Mobile — toast de notificacao in-app** (`widgets/notificacao_toast.dart`): card desliza do topo ~4s (estilo push), COLORIDO por tipo (aceite=verde, recusa=vermelho, mensagem=azul, prestacao=teal, avaliacao=ambar, doacao=verde, campanha=laranja, favorito/necessidade=indigo), com fila (1 por vez). Poller na MainShell a cada 20s (1a leitura = linha de base p/ nao avisar as antigas); toca -> central de notificacoes. Sem plugin nativo.

**GOTCHA de operacao (relançar apps localmente):** parar um `flutter run`/`mvnw spring-boot:run` pela ferramenta mata o WRAPPER mas deixa o processo FILHO (dart dev server / java) segurando a porta (8080 / 5599 / 5601) -> o relance falha com "porta em uso" (errno 10048). Fix: `netstat -ano | grep ":<porta> " | grep LISTENING` e `taskkill //PID <pid> //F`, depois relançar. Backend local: `JAVA_HOME` = JBR do IntelliJ (`C:/Program Files/JetBrains/IntelliJ IDEA 2025.3.3/jbr`, Java 21) + `./mvnw spring-boot:run`; apps: `flutter run -d chrome --web-port=5599` (desktop) / `5601` (mobile). Login demo: ONG demo.larviva@connectong.com / doador demo.joao@connectong.com / senha demo123.
