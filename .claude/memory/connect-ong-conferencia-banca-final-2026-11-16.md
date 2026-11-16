---
name: connect-ong-conferencia-banca-final-2026-11-16
description: "Conferência de 16/11/2026, dois dias antes da banca final (18/11) — tudo verde em produção; o que falta é humano (vídeo e atualizar o notebook da apresentação)"
metadata:
  node_type: memory
  type: project
  originSessionId: 35ee9f2c-3528-4c40-8211-458efb836d58
  modified: 2026-11-16T13:08:31.518Z
---

Conferência pedida pelo usuário na máquina de EDIÇÃO (`01gabriel.MAQCHINELATTO`), 2 dias antes da **banca final de 18/11/2026**. Decisão dele: "o que foi feito foi e o que não foi feito já foi" — nada de feature nova.

**Resultado: tudo verde.** Conferido ao vivo, não por memória:
- **Testes:** backend **232** · doador **124** · painel **75** = **431**, todos verdes nesta máquina.
- **Produção:** site, app do doador e painel respondendo 200; console do site sem erro; CI dos commits de 26/10 verde nos 4 repos.
- **Criptografia:** `/publico/seguranca` → `criptografiaEmRepouso: true`; login do doador demo lê telefone e as 72 mensagens sem nenhuma ilegível.
- **IA:** `/ia/status?ping=true` → `modo:"ia"`, `ping:"ok"`, cadeia `gpt-oss-120b → gpt-oss-20b → qwen3.8-27b`.
- **Validação (a crítica da FECITEC):** o cadastro publicado recusa nome com número, senha fraca, telefone inválido e falta de aceite, os 4 de uma vez; CNPJ com dígito errado recusado.
- **Demo intacta:** Lar Viva (ongId 33) com **2 interesses PENDENTES** para aceitar ao vivo; indicadores da ONG 60% de atendimento.
- **F-12 (paginar `/necessidades`) continua não feito** — 2,8 MB em 3,6 s; o documento final já declara isso, está coerente.

**Corrigido nesta conferência (commits de 16/11):**
- Documento final: números atualizados (431/232) e **seção 3.11** com as duas correções de outubro — o emoji que derrubava o "Salvar" do perfil da ONG e o modelo `qwen3.6` desligado pela Groq. Sem isso a banca veria divergência entre o PDF e o sistema.
- **Ping "Manter API acordada": 30 de 30 execuções vermelhas.** Causa: acordar do zero passa de 120 s e o `curl --max-time 120` desistia. Subido para 300 s (job 10 min). **Why:** o cron do GitHub rodou **~5x por dia** apesar de pedir a cada 10 min (ele atrasa muito cron de repo público sem atividade) — ou seja, **o ping NÃO mantém a API quente**. Medido: 1ª chamada **estourou 120 s**; a seguinte, 1,4 s. **How to apply:** antes de qualquer apresentação, abrir a API/o site na mão uns 5 min antes, ou disparar o workflow por "Run workflow".
- `COMO-MOSTRAR.md` aponta o roteiro da banca e traz essa espera medida.

**Pendências HUMANAS (não dá para fazer daqui):**
1. **Vídeo de 5 a 10 min** — o roteiro pronto está em `docs/entregas/Connect-ONG-Roteiro-do-Video.pdf` (9 min 45 s, falas divididas 4/4/3/3). O documento final **não tem campo para o link**: se o usuário mandar o link, inserir na capa e regerar o PDF.
2. **Computador da apresentação** — esta sessão NÃO conseguiu verificar o estado dele. Indício de que foi mexido em 26/10: o roteiro cita `chave-cripto.txt` na pasta FEIRA ESCOLA e o commit do site conta que o `INICIAR-FEIRA.bat` tinha caminho fixo e quebrava em outra máquina. Na dúvida, rodar lá o [checklist](connect-ong-atualizar-outro-computador-2026-09-22.md): puxar os 4 repos, chave de criptografia local, `RECOMPILAR-FEIRA`, substituir os 4 PDFs.
3. Os **4 PDFs** (Plano de Ação, Entrega Final, Resumo do que mudou, Roteiro do Vídeo) estão em `docs/entregas/` e copiados para `Desktop\Connect ONG - Entregas\` desta máquina.

Ver [[connect-ong-plano-acao-pos-fecitec-2026-09-22]].
