---
name: connect-ong-remodel-mobile
description: "Bloco 21 — plano de remodelação visual do app mobile (doador): design system + shell de navegação, referências iFood/Instagram, decisões travadas"
metadata: 
  node_type: memory
  type: project
  originSessionId: 94e5d7e8-f693-49dd-b45d-b37878aaeafe
---

Remodelação profissional do app MOBILE (doador) = Bloco 21 do [[connect-ong-roadmap]]. Objetivo: sair de "coleção de telas" para produto coeso. Iniciado 2026-07-02 (sessão pós-segurança).

**Decisões travadas com o usuário:**
- Identidade visual: **manter o verde/marca atuais e ELEVAR** (construir design system profissional em cima, não redesenhar identidade).
- Assistente/IA: **deixar para o fim** (foco em redesign + features primeiro). Quando vier, será **por regras (árvore de decisão/FAQ, zero tokens, offline)** — IA generativa real custa tokens inerentemente.
- Preview: usuário escolheu emulador Android, MAS o **Android SDK não está instalado** (flutter doctor negativo) → instalar Android Studio+SDK é mudança de sistema (vários GB). Alternativa sem instalar = Chrome device toolbar (Ctrl+Shift+M). [decisão de qual usar pendente]
- Escopo: **remodelar o mobile INTEIRO**, em fases com commit/push por checkpoint. As referências (iFood/Instagram) são para COMPLEMENTAR, não clonar.

**Problemas confirmados no código (grounding):**
- `HomeDoadorScreen` = grid de ~15 botões que fazem `Navigator.push` para telas soltas. **NÃO há bottom nav fixa** → é a raiz do "tudo espalhado sem padrão".
- "Minhas Doações" chama `GET /doacoes` **sem filtro** → backend devolve TODAS as doações do sistema (mesma lista p/ todos). Bug de dados real. Ainda usa a tabela legada `doacao` (marcada p/ remoção no [[connect-ong-deferred]]). Doações reais por usuário = `DoacaoFinanceira` (filtra por doadorId).
- Cores/estilos hardcoded espalhados (sem design system) — já flagrado no audit.

**Direção de design (referência iFood adaptada ao contexto de causa/impacto, não marketplace):**
- Bottom nav fixa de 5 abas absorvendo as 15 telas: **Início** (home curada) / **Explorar** (feed+busca+ranking) / **Matches** (hero: match+chat) / **Impacto** (minhas doações reais+mural+conquistas+PDF) / **Perfil** (conta+editar foto+favoritos+config+ajuda).
- Mapeamento iFood→nosso: carrossel promos→campanhas+necessidades urgentes; clube/diamante→gamificação (conquistas/pontos que já existem); lojas em destaque→ONGs verificadas/mais apoiadas; pedidos→histórico de doações/impacto; busca com filtro bonito.
- Login estilo Instagram: imagem + frase de impacto + **números reais** de `/publico` (ONGs, R$ doado, necessidades) para gerar confiança.
- Foto de perfil da GALERIA (não URL): `image_picker` no app + endpoint de upload no backend (arquivo ou base64) → toca backend, é feature. Já no backlog "upload de imagens".
- Gráficos: SVG/flutter_svg, cores da marca (ver [[preferencia-graficos]]).

**Roadmap em fases (commit/push a cada fase estável):** 0 Fundação/design system (tokens+componentes) → 1 Shell de navegação (bottom nav 5 abas) → 2 Login/onboarding → 3 Home curada → 4 Redesenho tela-a-tela → 5 Correções de dados (minhas doações real) + foto galeria → 6 Extras (assistente por regras, gamificação, microinterações).
