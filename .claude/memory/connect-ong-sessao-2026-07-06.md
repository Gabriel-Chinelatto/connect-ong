---
name: connect-ong-sessao-2026-07-06
description: "Estado VIVO da sessão 2026-07-06: 2ª rodada de feedback do usuário (13 tópicos), plano em 3 ondas, contratos do bloqueio, decisões tomadas e como retomar se a sessão cair"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5efb506b-4e50-4863-bb56-8bc40ab1a110
---

Sessão de 2026-07-06 (PC principal). Usuário viu os 2 apps rodando (builds release nas portas 5100/5100 + API real 8080/MySQL escola) e mandou a **2ª rodada de feedback: 13 tópicos**. Autonomia TOTAL confirmada: **não parar entre ondas, commit+push por checkpoint, sem pedir autorização** (registrado em [[git-workflow-preferences]]). Ver também [[connect-ong-roadmap]] (histórico) e [[connect-ong-deferred]].

## Os 13 tópicos do usuário (com as decisões tomadas)
1. 🔥 do card #1 invisível (chama laranja sobre chip laranja) → chama BRANCA + dias no chip.
2. Editar perfil: **Estado ANTES de Cidade**, ambos por SELEÇÃO (UF dropdown alfabético → autocomplete de cidades daquela UF) — asset OFFLINE do IBGE (`assets/dados/municipios_por_uf.json`), mais seguro que API na rede da escola. Aplicar em editar perfil + cadastro doador (mobile) e cadastro/editar ONG (desktop).
3. Clicar em necessidade urgente/card do feed → **tela de DETALHE da necessidade** (nova; capa, ONG clicável, descrição, cidade, "postado há X", Tenho interesse). ONG em destaque → abre o perfil direto.
4. Feed: se já demonstrei interesse → botão vira "Interesse demonstrado" (desabilitado) e a necessidade vai pro FIM da lista.
5. Privacidade REAL: toggles "exibir telefone/e-mail" passam a valer no perfil público (backend omite); Configurações só aplicam com botão **"Salvar configurações"** (aparece quando algo muda).
6. Configurações mais bonitas + **alto contraste** e **navegação simplificada** de verdade (alto contraste = fundos puros/bordas/texto pesado; simplificada = desliga carrossel automático/animações/confete + alvos de toque maiores).
7. Impacto: 4 destinos DISTINTOS — Matches realizados→Ativas; ONGs apoiadas→Explorar; Interesses enviados→Aguardando; **stat "Aguardando resposta" SUBSTITUÍDO por "Doações PIX"**→Minhas Doações (decisão minha, usuário delegou).
8. "Abrir no Maps" falhou na web → fix: `launchUrl` direto sem `canLaunchUrl`, fallback copia o link. Aplicar em todo url_launcher dos 2 apps.
9. Cadastrar doação (oferta): cabeçalho claro "Nova doação — preencha os dados para disponibilizar sua doação a qualquer ONG que precise" (não é direcionada).
10. "Concluída só quando prestar contas?" → DECISÃO (opinião dada ao usuário): MANTER o modelo 2 etapas (CONCLUIDO no "doação recebida" + prazo 10 dias), senão a contagem regressiva/penalidade perdem sentido; na UI da aba Concluídas, chip "⏳ Aguardando prestação de contas" vs "✅ Prestação publicada". Fácil de trocar depois se ele preferir.
11. Distância/rota até a ONG → botão **"Como chegar"** abrindo Google Maps DIRECTIONS (https://www.google.com/maps/dir/?api=1&destination=<endereço ONG>; origem vazia = localização atual do usuário). Rota in-app exigiria API paga — descartado.
12. Explorar: ONG do card clicável → perfil; mostrar "há X dias" (backend expõe `dataCriacao` no NecessidadeResponseDTO).
13. **Bloqueio estilo WhatsApp**: chat com avatar/nome clicável → perfil; ONG bloqueia doador pelo perfil dele; doador bloqueado: ONG some do feed/busca/campanhas, perfil dela vira {bloqueado:true}, mensagens → 403. Desbloqueio na lista "Doadores bloqueados" das Configurações do desktop.

## Contratos fixados para o backend (frontends construídos contra eles)
- `POST /bloqueios` {doadorId} (só ONG, ongId do token, idempotente) → 200 {mensagem}; `DELETE /bloqueios/{doadorId}`; `GET /bloqueios` → [{doadorId, doadorNome, criadoEm}].
- Enforcement: POST /mensagens → 403 genérico p/ bloqueado; GET /necessidades, /campanhas e /ongs filtram ONGs bloqueadoras quando o requisitante é doador logado (anônimo não filtra); GET /ongs/{id}/perfil-publico p/ doador bloqueado → {id, nome, bloqueado:true}; GET /interesses?doadorId= inclui `bloqueadoPelaOng:true` nos matches afetados.
- Privacidade: perfil-publico da ONG omite email/telefone conforme campos da entidade Preferencia (nomes reais = descobrir na entidade; agente reporta).
- `NecessidadeResponseDTO.dataCriacao` (datetime; null nas antigas se coluna nova).

## Plano em 3 ondas (estado ao gravar esta memória)
- **ONDA 1 (RODANDO agora, 3 agentes paralelos lançados ~08:40)**:
  (a) BACKEND: bloqueio+privacidade+dataCriacao, testes MockMvc, live H2 na porta 8099 (NUNCA 8080 — tem demo rodando), commit/push master. Base: 82 testes.
  (b) MOBILE 1 (repo connect-ong): tópicos 1, 3, 4, 7, 9, 10(chip), 12 — tudo UI local, degrada sem backend novo. Base: 50 testes.
  (c) DESKTOP: tópico 13 (UI bloqueio: botão no PerfilPublicoDoadorScreen + lista nas Configurações + chat header clicável), 8 (fix Maps), 5 (Salvar configurações), 2 (UF/cidades no cadastro/editar ONG + geração do asset IBGE). Base: 13 testes.
- **ONDA 2 (disparar quando Mobile 1 terminar — mesmo repo)**: MOBILE 2: tópico 2 (UF/cidades no editar perfil + cadastro; copiar/gerar mesmo asset IBGE), 6 (configurações bonitas + alto contraste/nav simplificada REAIS via ConfigController), 5 (botão Salvar no mobile), 8 (fix Maps mobile), 11 (Como chegar), 13 lado doador (chat header → perfil ONG; tratar 403 de mensagem; perfil {bloqueado:true} → tela "Você não pode ver este perfil"; feed já vem filtrado do servidor).
- **ONDA 3**: E2E do bloqueio ao vivo (H2), verificação visual por screenshots (harness JÁ VERSIONADO: `lib/main_screenshots.dart` + `tool/screenshots/`; gotchas: build RELEASE, iframe 430px p/ viewport mobile, `--virtual-time-budget=6000` p/ telas com timer, 20000 p/ painel), rebuild dos 2 apps + servidores 5100/5200 (script `scratchpad/servidor.dart` — recriar de qualquer pasta build/web se sumir), memórias + relatório final.

## Como retomar se a sessão cair/limite estourar
1. `git log` nos 3 repos p/ ver o que já entrou (mobile/desktop=main, backend=master; commits em português sem co-autoria).
2. Agentes de fundo podem ser retomados com SendMessage; se a sessão morreu de vez, relançar agentes novos com os mandatos acima (os contratos estão nesta memória).
3. Ambiente demo que estava no ar: API real porta 8080 (MySQL escola), apps release 5100/5200 (builds ANTIGOS, pré-rodada) — rebuildar na Onda 3.
4. Limites de sessão já estouraram 2x em 2026-07-03 (13:40 e 19:30) — retomada com SendMessage funcionou perfeitamente nas duas.
