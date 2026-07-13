---
name: connect-ong-inventario-doador
description: Inventário COMPLETO das funcionalidades/telas/serviços do DOADOR (mobile) — catálogo de referência para replicar na WEB (web=doador)
metadata: 
  node_type: memory
  type: reference
  originSessionId: e54bdb36-998f-43b3-8c56-301ef4baf242
---

Catálogo de TUDO que o DOADOR tem hoje (app `connect-ong`, Flutter). Serve de referência para construir a WEB (que deve ser experiência de doador — ver [[connect-ong-web-doador-plano]]). O app do doador JÁ compila e roda na web; o `main_shell` já é responsivo (NavigationRail ≥900px). Arquitetura geral em [[connect-ong-architecture]]; roadmap em [[connect-ong-roadmap]].

## Shell / navegação (`lib/doador/main_shell.dart`)
5 abas com `IndexedStack` + `NavigationBar` (celular) / `NavigationRail` (desktop/web ≥900px, conteúdo com largura máx 840): **Início, Explorar, Matches, Impacto, Perfil**. Navegação fluida (fade+slide, ícone vazio→cheio, haptic). Poller de notificações → toast in-app.

## Telas do doador (`lib/doador/`, 27 arquivos)
- **inicio_tab** — home curada: saudação + frase motivacional, sino (`NotificacaoBell`), avatar/foto, busca→Explorar, botão **Dora** (IA), card "Seu impacto" (nº matches), acesso rápido (Buscar ONGs, Minhas doações, Favoritos, Atividades, Nosso impacto, Ranking), carrosséis Campanhas (vivo/auto), Necessidades urgentes, ONGs em destaque (ranking), **Sugestões para você (IA)**.
- **feed_necessidades_screen** — Explorar: lista/busca de necessidades, filtros categoria + UF/cidade (IBGE offline).
- **necessidade_detalhe_screen** — detalhe + demonstrar interesse.
- **meus_matches_screen** — 3 sub-abas Ativas/Aguardando/Concluídas; dias esperando; recusa reabre com CTA.
- **chat_screen** — chat com a ONG estilo WhatsApp (anexos, bloqueio, digitando, visto por último, fuso corrigido).
- **dashboard_impacto_screen** — métricas do doador, streak 🔥, 4 destinos de impacto.
- **mural_impacto_screen** / **timeline_atividades_screen** — mural coletivo + timeline de atividades.
- **perfil_screen** / **editar_perfil_screen** — perfil próprio + edição (foto base64).
- **perfil_publico_doador_screen** — perfil público do doador + avaliação estilo Uber (ONG→doador, com foto).
- **perfil_publico_ong_screen** — perfil rico da ONG: capa, avatar, selo verificação, nota (estrelas), pill de transparência (Ouro/Prata/Bronze + score), streak, Sobre, **Resumo de impacto (IA)**, contato (email/telefone conforme privacidade), endereço + **Abrir no Maps / Como chegar / Simular frete**, fotos do local, campanhas, necessidades clicáveis, prestações (agrupadas por doador), avaliações; compartilhar (link `/#/ong/<id>`), denunciar.
- **simular_frete_sheet** — simulador de frete (origem=cidade doador, destino=cidade ONG; distância IBGE offline+Haversine; peso pela IA; seletor de categoria; aviso de categoria divergente). Rotulado ESTIMATIVA.
- **assistente_screen** (Dora) — chat IA grounded, análise de foto (visão), histórico estilo ChatGPT (`conversas_dora_service`).
- **doar_pix_screen** — doação em dinheiro via PIX (2 fases).
- **cadastrar_doacao_screen** / **minhas_doacoes_screen** — registrar doação (item/foto) + histórico.
- **campanhas_screen** — campanhas com meta/progresso.
- **prestacoes_screen** — prestação de contas.
- **favoritos_screen** — ONGs favoritas.
- **conquistas_screen** — gamificação/badges.
- **ranking_transparencia_screen** — ranking de ONGs por transparência.
- **buscar_receptor_screen** — busca de ONGs.
- **notificacoes_screen** — notificações (marcar 1 como lida ao tocar).
- **configuracoes_screen** — aparência (dark mode), alto contraste, fonte dislexia, navegação simplificada, notificações, privacidade (mostrar email/telefone, perfil público), segurança (2FA, trocar senha/email, excluir conta), acessibilidade.
- **sugestoes_para_voce** (widget) — cards IA no Início.

## Serviços (`lib/services/`, 26) — camada de API (pacote `http`, base `localhost:8080`)
api_service (JWT, timeout 12s, 401 global, mensagens amigáveis), auth_service, login_service, session_service, perfil_service, perfil_publico_service, necessidade_service, interesse_service (matches), mensagem_service (chat), doacao_service, doacao_financeira_service (PIX), campanha_service, favorito_service, avaliacao_service, prestacao_service, atividade_service, ranking_service, estatistica_service, conquista_service, notificacao_service, preferencia_service, denuncia_service, relatorio_pdf_service, conversas_dora_service, **assistente_service** (Dora + `/assistente/sugestoes`), **resumo_impacto_service**, **frete_service**.

## IA (Groq gratuita, chave NO BACKEND, fallback por regras em tudo) — ver [[connect-ong-frete-e-ia-2026-07-10]] e [[connect-ong-assistente-ia]]
Dora (chat + visão), peso/categoria do item, frete estimado, resumo de impacto da ONG, sugestões proativas por perfil/cidade. (No lado ONG/desktop: escrever necessidade e "Sobre" com IA + loop de refino.) Temperatura por tarefa (0.15 extração / 0.5–0.55 escrita), max_tokens por chamada, prompts endurecidos, rate limit por endpoint.

## Endpoints backend relevantes ao doador
`/usuarios` (registro/perfil/senha/email), `/login`, `/2fa`, `/senha-reset`, `/ongs` (perfil público), `/necessidades`, `/interesses`, `/mensagens`, `/doacoes`, `/contribuir` (PIX), `/campanhas`, `/avaliacoes`, `/favoritos`, `/prestacoes`, `/atividades`, `/ranking`, `/estatisticas`, `/conquistas`, `/notificacoes`, `/preferencias`, `/denuncias`, `/categorias`, `/assistente` (+`/sugestoes`), `/frete/estimar`, `/ia/redacao`, `/ia/resumo-impacto`, `/ia/sobre-ong`.

## Design system (`lib/theme/`)
`AppColors` (primary verde `0xFF0A8449`, ouro/prata/bronze, error/warning/info), `AppRadius`, `AppSpacing`. Dark mode completo, alto contraste, fonte dislexia, textScale. Regra de gráficos: SVG/imagens free nas cores da marca ([[preferencia-graficos]]). Tudo em PT-BR ([[preferencia-idioma]]).
