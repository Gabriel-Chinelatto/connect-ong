---
name: connect-ong-deferred
description: "Connect ONG — backlog único de itens ADIADOS durante os blocos (recapitular após o Bloco 30 se sobrar tempo)"
metadata:
  node_type: memory
  type: project
  originSessionId: fd5869c2-ce42-4ab3-b411-545f30b4d907
---

Backlog de coisas conscientemente **deixadas para depois** ao longo dos blocos. Recapitular após terminar os 30 blocos (ver [[connect-ong-roadmap]]). Cada item: origem → o quê → por que adiado. Marcar com ✅ quando resolvido.

## Segurança / conformidade
- **[ ] JWT enforcement OFF** (Bloco 15): o JWT é gerado/validado e demonstrável, mas a exigência do token nos endpoints está DESLIGADA por decisão do usuário (estabilidade durante o dev). Ativar perto da entrega final, quando tudo estiver validado.
- **[ ] Senha do banco no histórico do git** (sessão inicial): a senha foi externalizada para `application-local.properties` (gitignored), MAS commits antigos ainda contêm a senha em texto puro no histórico. Rotacionar a senha do MySQL e/ou limpar o histórico antes de tornar o repo público de verdade.

## Banco de dados
- **[ ] Migrar para utf8mb4** (gotcha recorrente): o MySQL 5.6 usa utf8 (3 bytes) → emojis (4 bytes) dão 500 "Incorrect string value" ao salvar. Hoje contornamos não salvando emoji no banco. Fix definitivo = migrar colunas para utf8mb4.
- **[ ] Baseline completo no Liquibase** (Bloco 17): as tabelas existentes não estão no changelog (predatam o Liquibase). Gerar baseline com `liquibase generateChangeLog` para reproduzir o schema do zero. (Documentado em docs/NORMALIZACAO.md.)
- **[ ] Remover tabela legada `doacao`** (Bloco 17): existe no banco mas não faz mais parte do fluxo. (OBS: a tabela `projeto` NÃO é morta — será reaproveitada como Campanha no Bloco 22.)
- **[ ] FK formal em `usuario.ong_id`** (Bloco 17): hoje é vínculo por id sem constraint; avaliar adicionar FK para integridade referencial no nível do banco.

## DevOps
- **[ ] Validar build da imagem Docker** (Bloco 18): Dockerfile/compose criados mas NÃO validados localmente (Docker não está instalado na máquina). Rodar `docker compose up --build` quando houver Docker.
- **[ ] Hospedar o build web** (Bloco 19): `flutter build web` OK, mas não publicado. Deploy opcional em GitHub Pages/Netlify para ter URL pública.
- **[ ] Push para ativar as CIs** (Bloco 18): os 3 workflows do GitHub Actions rodam no push/PR; ainda não foram pushados (regra: só pushar quando o usuário pedir).

## Funcionalidades
- **[ ] Cadastro de doador no mobile** (visto no Bloco 15): o botão "Cadastre-se" no login do app mobile é um no-op — não há auto-cadastro de doador. Construir a tela de signup do doador (com checkbox de consentimento LGPD, como já feito no cadastro de ONG no desktop).
- **[ ] Upload de imagens** (absorvido do roadmap #16): logo da ONG, foto de perfil e fotos de prestação hoje são `fotoUrl` (string), sem mecanismo de upload real. Adicionar quando necessário.
- **[ ] Lista "doações recebidas" no painel da ONG (desktop)** (Bloco 14): a ONG já recebe notificação de doação PIX, mas não há uma tela listando as doações financeiras recebidas. Pequeno add futuro.
- **[ ] WebSocket no chat** (Bloco 11): decisão foi usar polling (2s) agora; WebSocket adiado para real-time mais eficiente.

## Visual
- **Polimento visual forte** = Bloco 21 (já é um bloco planejado do roadmap, não um item solto). Usuário sinalizou (2026-06-24) que a UI está "feinha" apesar da funcionalidade rica.
