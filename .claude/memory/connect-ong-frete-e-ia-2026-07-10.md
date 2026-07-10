---
name: connect-ong-frete-e-ia-2026-07-10
description: Sessão 2026-07-10 (2ª do dia) — navegação fluida no doador + simulador de frete + IA (Groq) expandida em 4 frentes; verificado ao vivo
metadata: 
  node_type: memory
  type: project
  originSessionId: e54bdb36-998f-43b3-8c56-301ef4baf242
---

Sessão 2026-07-10 (depois da de engajamento). O usuário pediu 3 coisas no app do DOADOR (+ melhoria no desktop pela IA) e eu decidi a rota com ele via perguntas. **Tudo feito, testado (152 testes backend verdes) e verificado AO VIVO por HTTP.** Commitado e enviado nos 3 repos.

## 1) Navegação fluida no doador
Antes o [lib/doador/main_shell.dart](lib/doador/main_shell.dart) usava `NavigationBar` + `IndexedStack` que trocava a aba no **corte seco** (sensação "não profissional" que o usuário reclamou). Os ícones vazio→cheio (`selectedIcon`) já existiam. Adicionei: `AnimationController` (260ms) que dá **fade + micro-slide** de entrada na aba (preservando o estado do IndexedStack via `_conteudoAnimado`), **"pulinho" de escala** no ícone recém-selecionado (`_iconeSelecionado`, easeOutBack) e **HapticFeedback.selectionClick()** no toque. Aplicado nos dois layouts (NavigationBar celular + NavigationRail desktop).

## 2) Simulador de frete (decisão: ESTIMATIVA offline, não API real)
Por quê estimativa e não frete real: **não existe CEP nem lat/long em nenhuma entidade** (Usuario/Ong só têm cidade; Ong tem endereço texto; Usuario tem estado/UF). APIs reais (Frenet/Correios/Melhor Envio) exigem CEP+dimensões+internet → risco na feira. O usuário escolheu o **simulador inteligente** (rotulado "estimativa").
- Backend novo: `GeoService` carrega `src/main/resources/geo/municipios.json` (5571 cidades IBGE, baixado de kelvins/municipios-brasileiros) + `estados.json`, e faz **Haversine** offline. `ItemIaService` estima **peso+categoria** do item (IA Groq com fallback por regras/tabela de pesos). `FreteService`+`FreteController` = `POST /frete/estimar`.
- Fórmula (em application.properties, `app.frete.*`): Correios = 15 + 1.2/kg + 0.09/km; Transportadora = 20 + 0.7/kg + 0.06/km; **"Entrega combinada" grátis quando distância ≤ 30 km**; cidade fora da base → 300 km + aviso.
- Mobile: [lib/services/frete_service.dart](lib/services/frete_service.dart) + folha [lib/doador/simular_frete_sheet.dart](lib/doador/simular_frete_sheet.dart) (origem = cidade do doador via PerfilService; destino = cidade da ONG). Botão **"Simular frete"** no Wrap ao lado de Maps/Como chegar em [lib/doador/perfil_publico_ong_screen.dart](lib/doador/perfil_publico_ong_screen.dart).
- **Verificado ao vivo:** Limeira→Rio = 432 km (real), peso 10kg, Correios R$65,88 / Transportadora R$52,92; mesma cidade = 0 km + "Entrega combinada".

## 3) IA (Groq) expandida — o usuário quis TODAS as 4
Reusa `ProvedorIA.completar` (Groq gratuita) com **fallback por regras** (funciona sem chave = modo "regras"). Endpoints públicos (whitelist em SecurityConfig) com rate limit próprio.
- **Peso/categoria do item** (`ItemIaService`) — alimenta o frete.
- **Redação da necessidade** (`RedacaoService`, `POST /ia/redacao`) — DESKTOP da ONG: botão **"Escrever com IA"** (Icons.auto_awesome) no `_FormNecessidade` de [painel_ong_screen.dart](../../../connect_ong%20-%20Desktop/lib/screens/ong/painel_ong_screen.dart) + [lib/services/ia_service.dart](../../../connect_ong%20-%20Desktop/lib/services/ia_service.dart). Reescreve rascunho→título+descrição.
- **Resumo de impacto** (`ResumoImpactoService`, `POST /ia/resumo-impacto` {ongId}) — MOBILE: widget [lib/widgets/common/resumo_impacto_ia.dart](lib/widgets/common/resumo_impacto_ia.dart) no perfil da ONG (após "Sobre"), degrada para nada se falhar. ongId inválida → resumo genérico modo regras (200, não 404).
- **Sugestões por perfil/cidade** (`AssistenteService.sugerirParaDoador()`, `POST /assistente/sugestoes`, SEM body) — MOBILE: seção **"Sugestões para você"** [lib/doador/sugestoes_para_voce.dart](lib/doador/sugestoes_para_voce.dart) no Início (após acesso rápido). Reusa `AssistenteResponseDTO`/`RespostaAssistente`+`SugestaoAssistente` (cards clicáveis ONG/necessidade). Anônimo → "em destaque"; com token → "perto de você"/"com base no que você doa".

## Estado / gotchas
- **A chave da Groq ESTÁ no application-local.properties desta máquina** → live retornou `modo:"ia"` (redação e frete com IA real). Na feira sem chave cai em "regras" (ainda funciona).
- ⚠️ **A instância do backend na porta 8080 (a que o usuário roda) é a build ANTIGA** — precisa **reiniciar o backend** para os endpoints novos aparecerem para os apps (que apontam localhost:8080). Testei numa 2ª instância na 8081 e encerrei.
- Gotcha de verificação: subir 2ª instância com `mvnw spring-boot:run "-Dspring-boot.run.arguments=--server.port=8081"`; matar o **java** que escuta na porta (processo-filho do cmd/mvnw), não só o cmd.
- `GET /ongs` exige token (privacidade de sessão anterior) — por isso o resumo-impacto com ONG real não foi puxado no teste; só o caminho genérico.
- Pendências humanas herdadas (fora do escopo): senha MySQL no git a rotacionar; `APP_DEMO_ENABLED=true` na máquina da feira.
- Backend=master, mobile/desktop=main. Todos commitados+push. Relacionado: [[connect-ong-assistente-ia]], [[connect-ong-engajamento-2026-07-10]].
