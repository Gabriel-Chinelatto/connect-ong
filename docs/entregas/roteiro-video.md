# Roteiro do vídeo final — Connect ONG

> **ATENÇÃO À DURAÇÃO.** A `Connect-ONG-Entrega-Final.pdf` (seção 7) registra a
> exigência do professor como **vídeo de 5 a 10 minutos (seção 4.1 do PDF dele)**.
> Este roteiro foi montado em **~13 minutos**, a pedido da equipe. Os blocos
> marcados **[CORTÁVEL]** somam ~3:30 e, removidos, fecham o vídeo em **~9:30**.
> **Confirmar a duração correta no PDF do professor antes de gravar.**

Escrito em 26/10/2026.

## Antes de gravar — o que precisa estar pronto

- [ ] **A chave `APP_CRYPTO_KEY` configurada na máquina que vai gravar.** Sem
      ela o bloco 5:15 (criptografia) **não tem o que mostrar**: a linha do
      banco aparece em texto normal e `/publico/seguranca` responde
      `criptografiaEmRepouso: false`. Ver `chave-cripto.txt.EXEMPLO` na pasta
      FEIRA ESCOLA.
- [ ] `INICIAR-FEIRA.bat` rodado e as 3 telas no ar.
- [ ] `/ia/status?ping=true` respondendo `ok` (senão a Dora grava em "modo
      básico" e o bloco 10:45 fica fraco).
- [ ] `RESTAURAR-DEMO.bat` rodado, para a Lar Viva ter pedidos pendentes para
      aceitar ao vivo no bloco 2:10.
- [ ] Contas: doador `demo.joao@connectong.com`, ONG
      `demo.larviva@connectong.com`, senha `demo123`.

## Divisão das falas

Cada um fala da frente que implementou (mesma divisão do Plano de Ação, onde
cada integrante tem 4 itens do backlog):

| Integrante | Frente | Fala sobre |
|---|---|---|
| Gabriel Chinelatto | Back-end e design | abertura, match → chat, criptografia, IA |
| Luan Felipe | Back-end | chat, validação na API, indicadores |
| Abner Viola | Front-end | validação nas telas, LGPD, página para empresas |
| Arthur Souza | Design e testes | problema/solução, modelo de negócios, testes |

A fala **não precisa durar o tempo todo do bloco** — entra música de fundo e
legenda para completar. Falas curtas, tom de conversa.

---

## Roteiro

### 0:00 ~ 0:30 — Abertura: logo do projeto e os 4 integrantes na tela
**Gabriel:**
> "Somos a equipe do Connect ONG. Nosso projeto liga quem quer doar às ONGs que
> precisam. Hoje a gente vai mostrar o que mudou depois da Feira de Tecnologia."

### 0:30 ~ 1:10 — Site institucional, página inicial, rolando devagar
**Arthur:**
> "O problema é simples: quem quer doar não sabe para quem doar, e a ONG não
> consegue avisar do que precisa. O Connect ONG resolve os dois lados — a ONG
> publica o que precisa, e o doador encontra."

### 1:10 ~ 2:10 — App do doador: lista de necessidades → "Tenho interesse"
**Gabriel:**
> "A banca de qualificação pediu mais interação entre as pessoas. Esta é a
> resposta: a ONG publica uma necessidade, e o doador demonstra interesse com
> um toque."

### 2:10 ~ 3:00 — Painel da ONG: aceitar o pedido → o chat abre sozinho → trocar duas mensagens
**Luan:**
> "Quando a ONG aceita, o chat abre automaticamente. Ninguém precisa procurar
> contato, nem trocar telefone. A conversa já nasce ligada àquela doação."

### 3:00 ~ 4:15 — Site, cadastro de ONG: CNPJ inválido, telefone "abc", senha "123456"
Mostrar os erros aparecendo embaixo de cada campo, antes de enviar.

**Abner:**
> "O avaliador disse que dava para colocar o que quisesse em qualquer campo.
> Agora não dá. O CNPJ passa pela conta do dígito verificador, o telefone
> precisa de um DDD que exista, e senha fraca não entra."

### 4:15 ~ 5:15 — [CORTÁVEL] Swagger ou terminal: a mesma requisição direto na API, voltando 400
**Luan:**
> "E a validação não está só na tela. Está no servidor também. Quem tentar
> falar direto com a API, sem passar pelo site, recebe a mesma recusa."

### 5:15 ~ 6:30 — Chat no app → a mesma linha no banco embaralhada → `/publico/seguranca`
**Gabriel:**
> "Outro ponto foi a falta de criptografia. Hoje o telefone do doador, as
> mensagens do chat e as denúncias ficam embaralhados no banco, com AES-256. A
> chave fica fora do programa. Aqui o sistema mostra exatamente o que está
> protegido."

### 6:30 ~ 7:45 — App: "Privacidade e meus dados" → baixar o arquivo → abrir e mostrar
**Abner:**
> "O avaliador também falou de LGPD. Agora o usuário baixa tudo o que o sistema
> guarda sobre ele, vê o consentimento que deu, e pode apagar a conta de
> verdade — o nome é substituído, não fica guardado."

### 7:45 ~ 9:00 — Painel da ONG: tela "Indicadores" (funil, taxa de atendimento, tempo de resposta)
**Luan:**
> "Antes a gente só mostrava quantas ONGs e quantos doadores tinha. Isso diz o
> tamanho, não diz se funciona. Agora acompanhamos o caminho inteiro:
> necessidade publicada, interesse, aceite e doação concluída."

### 9:00 ~ 10:00 — Slide do Lean Canvas
**Arthur:**
> "A Feira apontou que o projeto era pouco pensado para o mercado. A nossa
> decisão principal: não cobrar nada sobre a doação. Quem paga é a empresa que
> quer usar a plataforma no programa social dela. ONG e doador nunca pagam."

### 10:00 ~ 10:45 — [CORTÁVEL] Site: página "Para empresas", mostrando os planos
**Abner:**
> "E isso saiu do papel: o site tem a página para empresas, com os planos."

### 10:45 ~ 11:30 — Assistente Dora respondendo, com o aviso de IA visível
**Gabriel:**
> "Usamos inteligência artificial para ajudar a ONG a se apresentar. Antes de
> enviar qualquer texto, o sistema tira e-mail, telefone e CPF. E toda tela
> avisa que a resposta é gerada por IA."

### 11:30 ~ 12:15 — [CORTÁVEL] Terminal rodando os testes, terminando em verde
**Arthur:**
> "São 430 testes automáticos. Eles rodam antes de cada entrega, e nada vai pro
> ar com algum deles falhando."

### 12:15 ~ 13:00 — Encerramento: os 4 integrantes na tela
**Gabriel:**
> "Dos cinco pontos apontados na Feira, corrigimos os cinco."

**Arthur:**
> "Dois a gente decidiu não fazer, e está documentado o porquê."

**Luan:**
> "Falta dividir a lista de necessidades em páginas, para quando a base crescer."

**Abner:**
> "E até a banca final: validar com três ONGs de Limeira. Obrigado!"

---

## Se precisar cortar para 10 minutos

Remover os três blocos [CORTÁVEL] (4:15, 10:00 e 11:30) tira ~3:30 e o vídeo
fecha em ~9:30. Nenhum ponto dos avaliadores fica sem ser mostrado:

- O corte de 4:15 mantém a validação (fica só a parte da tela, no bloco 3:00).
- O corte de 10:00 mantém o modelo de negócios (fica a fala do Lean Canvas).
- O corte de 11:30 tira só os testes, que não foram um ponto apontado.

Se cortar, **Luan e Arthur perdem uma fala cada** — a avaliação olha a
participação de todos, então redistribuir: Luan assume o bloco 5:15 junto com
o Gabriel, e Arthur abre o encerramento.
