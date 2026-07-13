---
name: connect-ong-web-doador-plano
description: TAREFA PENDENTE — construir a WEB como experiência do DOADOR (visual chamativo). Analisar projeto e traçar rota quando o usuário mandar.
metadata: 
  node_type: memory
  type: project
  originSessionId: e54bdb36-998f-43b3-8c56-301ef4baf242
---

**Tarefa combinada em 2026-07-13, a executar QUANDO o usuário pedir** ("agora faça a web"). Não começar antes de ele mandar.

## Objetivo
A **WEB** deve ser um lugar de tela do **DOADOR**, com **visual muito chamativo** (o usuário enfatizou o apelo visual) e as **funcionalidades do doador**. Regra de plataforma passa a ser: **mobile + web = DOADOR; desktop = ONG** (antes a web era só um portal institucional). Ver as 3-plataformas em [[connect-ong-architecture]].

## Contexto importante (facilita muito o trabalho)
- **O app do doador JÁ compila e roda na web** (foi rodado no Chrome, `flutter run -d chrome`, em :5011 nesta sessão) e o `lib/doador/main_shell.dart` **já é responsivo** (usa `NavigationRail` em telas ≥900px e limita a largura do conteúdo a 840px). Ou seja, a base para "web = doador" já existe — falta polir o VISUAL para telas largas e o fluxo de entrada.
- **Estado atual da web (o que o amigo começou, "mal feito mas com base")**: existe UMA tela web dedicada — `lib/web/portal_institucional_screen.dart` — uma landing institucional (hero, faixa de estatísticas públicas, sobre, como funciona, ODS, equipe, FAQ, transparência, versões/changelog, rodapé) com botão "Entrar" → `LoginPage`.
- **Entrada web** em `lib/main.dart`: `kIsWeb ? EntradaWeb() : SplashDecider()`. `EntradaWeb` mostra o portal institucional e trata deep-link `/#/ong/<id>` (link compartilhado de ONG). Após login na web, cai no fluxo do doador (`MainShell`).
- Já habilitei arraste de listas horizontais com mouse na web (scrollBehavior global em main.dart).

## Rota de ataque provável (definir os detalhes na hora, analisando o código)
Quando mandar: analisar o projeto e o inventário do doador ([[connect-ong-inventario-doador]]) e decidir. Linhas gerais prováveis:
1. Transformar a web na experiência do doador reaproveitando as telas já responsivas, com um **hero/landing chamativo** (grid responsivo, max-width, tipografia forte, imagens/SVG originais da marca, animações sutis) e **CTA forte "Doar agora"** que leva ao app do doador (login/cadastro).
2. Decidir o papel do `portal_institucional_screen`: vira a landing de topo (marketing + transparência) com entrada clara para o doador, OU é substituído/absorvido. Manter a seção de transparência/estatísticas (bom para a banca).
3. Garantir que as funcionalidades do doador ficam BOAS em telas largas: feed/Explorar em grid, Dora, **simular frete**, matches/chat, impacto, perfil público da ONG, PIX, sugestões IA — sem parecer "app de celular esticado".
4. Não quebrar o mobile (mesma base de código; usar breakpoints/responsividade). Manter design system (`AppColors`/`AppRadius`/`AppSpacing`), dark mode, acessibilidade, PT-BR.

## Restrições / lembretes
- É para **fins demonstrativos na feira** (FECITEC / [[connect-ong-milestones]]) — priorizar impacto visual e as funcionalidades que impressionam a banca ([[connect-ong-banca-feedback]]: hero = match + chat + IA).
- Regras de entrega ([[connect-ong-delivery-rules]]): 3 frontends, commits por membro, RESTful.
- Preferências: gráficos em SVG/imagens free ([[preferencia-graficos]]); tudo em português ([[preferencia-idioma]]); auto-commit+push por checkpoint ([[git-workflow-preferences]]); sem prompts de permissão ([[permissoes-projeto]]).
- Backend/apps: apps apontam `localhost:8080`; reiniciar o backend após mudanças; IA ativa com chave em `application-local.properties` (na feira sem chave cai em modo regras).
