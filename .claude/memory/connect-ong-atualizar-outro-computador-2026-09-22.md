---
name: connect-ong-atualizar-outro-computador-2026-09-22
description: "CHECKLIST para o computador da entrega/feira depois de 22/09 — puxar os 4 repos, colocar APP_CRYPTO_KEY local, recompilar FEIRA ESCOLA e substituir os PDFs da pasta de entregas"
metadata: 
  node_type: memory
  type: project
  originSessionId: 35ee9f2c-3528-4c40-8211-458efb836d58
  modified: 2026-09-22T14:05:35.680Z
---

**Quando usar:** o usuário abrir um chat em OUTRO computador (notebook da feira `gabri` ou o computador da entrega) e disser algo como "atualize este computador com o que foi feito no outro" / "estou no computador da entrega". Tudo de 22/09/2026 foi feito na máquina principal (`01gabriel.MAQCHINELATTO`). Ver [[connect-ong-plano-acao-pos-fecitec-2026-09-22]].

**Checklist (nesta ordem):**
1. **Sincronizar os 4 repositórios** (skill `sincronizar` / `git pull`). Chega tudo: código novo (validação, criptografia, LGPD, indicadores), `docs/entregas/` com os PDFs e esta memória.
2. **Chave de criptografia (NÃO está no Git, de propósito):** pegar o valor de `APP_CRYPTO_KEY` no painel do Render (dashboard.render.com → connect-ong-api → Environment → olho ao lado do valor) ou pedir para o usuário colar. Colocar como `app.crypto.key=<valor>` no `application-local.properties` do backend daquela máquina E onde a pasta FEIRA ESCOLA passa as configurações para o jar (conferir os `.bat`; a chave da IA usa `chave-ia.txt`). **Why:** o banco da escola já está CIFRADO; sem a chave, telefones/mensagens aparecem como "[conteúdo protegido indisponível]", e com uma chave DIFERENTE o backend se recusa a subir (trava da `cripto_chave`). Nunca commitar a chave (repos públicos). Se possível, anotar também no `CONNECT-ONG-SEGREDOS.txt` daquela máquina.
3. **FEIRA ESCOLA** (se for o notebook): rodar `RECOMPILAR-FEIRA` para o jar e os builds web virarem a versão nova. O MySQL local da feira é uma cópia antiga em texto puro: com a chave, o backend cifra na subida (normal, ~1 min). Se rodar `ATUALIZAR-BANCO-DA-ESCOLA`, o dump já vem cifrado — por isso a chave é obrigatória antes.
4. **PDFs:** substituir os arquivos da pasta de entregas daquela máquina (`Área de Trabalho\Connect ONG - Entregas\`, criar se não existir) pelos de `connect-ong\docs\entregas\`: `Connect-ONG-Plano-de-Acao.pdf` (versão FINAL, data **23/09/2026**, dia da aula) e `Connect-ONG-Entrega-Final.pdf`. SÓ substituir os arquivos — o usuário pediu isso explicitamente.
5. Conferir: `GET /publico/seguranca` local → `criptografiaEmRepouso: true`; login `demo.joao@connectong.com`/`demo123` e abrir um chat (mensagem legível).

**Decisões do usuário (22/09):** nomes na entrega ficam "Luan Felipe" e "Arthur Souza"; divisão 4 itens por integrante; o Plano pode ser enviado ao professor; a Entrega Final é só depois (data a combinar).
