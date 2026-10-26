# Roteiro do vídeo final — Connect ONG

**Duração: 9 min 45 s** — dentro do limite de 5 a 10 minutos do item 4.1 do
enunciado. Escrito em 26/10/2026.

## O que o enunciado exige (item 4.1)

Vídeo único de **5 a 10 minutos**; abertura rápida de **15 a 20 segundos**;
**recapitulação em uma frase** do que a banca de qualificação e a Feira
apontaram; demonstração de cada melhoria **mostrando o sistema rodando — não é
slide** — e **citando de qual feedback ela veio**; comentário breve sobre o que
não foi concluído; fechamento com uma frase sobre o próximo passo até a banca
final.

Os blocos marcados **[EXIGÊNCIA]** atendem um pedido específico dele —
**não cortar nenhum**. Todo o resto é o sistema em funcionamento, nunca slide.

## Antes de gravar

- [ ] `INICIAR-FEIRA.bat` rodado e as três telas no ar.
- [ ] `RESTAURAR-DEMO.bat` rodado, para a Lar Viva ter pedidos pendentes para
      aceitar ao vivo no bloco das 1:40.
- [ ] **Conferir a criptografia:** abrir `127.0.0.1:8080/publico/seguranca` e
      ver `criptografiaEmRepouso: true`. Se vier `false`, falta o
      `chave-cripto.txt` na pasta FEIRA ESCOLA e o bloco das 3:55 não tem o
      que mostrar.
- [ ] `/ia/status?ping=true` respondendo `ok` — senão a Dora grava em "modo
      básico" e o bloco das 8:05 fica fraco.
- [ ] Contas: doador `demo.joao@connectong.com`, ONG
      `demo.larviva@connectong.com`, senha `demo123`.

## Divisão das falas

| Integrante | Frente | Fala sobre | Falas |
|---|---|---|---|
| Gabriel Chinelatto | Back-end e design | abertura, match → chat, criptografia, IA | 4 |
| Luan Felipe | Back-end | chat, validação na API, indicadores, item não concluído | 4 |
| Abner Viola | Front-end | validação nas telas, LGPD, fechamento | 3 |
| Arthur Souza | Design e testes | recapitulação, mercado, item não concluído | 3 |

A fala **não precisa durar o tempo todo do bloco** — entra música de fundo e
legenda para completar. Falas curtas, em tom de conversa.

---

## Roteiro

### 0:00 ~ 0:20 — Abertura: logo do projeto e os 4 integrantes na tela  [EXIGÊNCIA]
*Ele pede abertura rápida, de 15 a 20 segundos. Não alongar.*

**Gabriel:**
> "Somos a equipe do Connect ONG — Gabriel, Abner, Luan e Arthur. Nosso projeto
> liga quem quer doar às ONGs que precisam."

### 0:20 ~ 0:45 — Tela do sistema já aberta ao fundo (site na página inicial)  [EXIGÊNCIA]
*A recapitulação em **uma frase** do que a banca e a Feira apontaram.*

**Arthur:**
> "A banca de qualificação disse que faltava interação entre as pessoas, e a
> Feira apontou cinco falhas: campos sem validação, falta de criptografia,
> falta de LGPD, poucos dados sobre resultados e pouca visão de mercado. É isso
> que a gente vai mostrar resolvido."

### 0:45 ~ 1:40 — App do doador: lista de necessidades → "Tenho interesse"
*Vem da banca: "pouca interação, sem comunicação entre doador e ONG".*

**Gabriel:**
> "A banca pediu mais interação entre as pessoas. Esta é a resposta: a ONG
> publica uma necessidade, e o doador demonstra interesse com um toque."

### 1:40 ~ 2:25 — Painel da ONG: aceitar → o chat abre sozinho → duas mensagens
*Vem da banca: a sugestão do match com chat automático depois do aceite.*

**Luan:**
> "Foi a própria banca que sugeriu isso: quando a ONG aceita, o chat abre
> automaticamente. Ninguém precisa trocar telefone — a conversa já nasce ligada
> àquela doação."

### 2:25 ~ 3:20 — Site, cadastro de ONG: CNPJ inválido, telefone "abc", senha "123456"
Mostrar os erros embaixo de cada campo, antes de clicar em enviar.
*Vem da Feira: "não tinha validações nos campos, podia colocar o que quisesse".*

**Abner:**
> "Na Feira o avaliador disse que dava para colocar o que quisesse em qualquer
> campo. Agora não dá: o CNPJ passa pela conta do dígito verificador, o
> telefone precisa de um DDD que exista, e senha fraca não entra."

### 3:20 ~ 3:55 — Swagger ou terminal: a mesma requisição direto na API, voltando 400
*Mesmo feedback da Feira, agora do lado do servidor.*

**Luan:**
> "E não está só na tela. Quem tentar falar direto com o servidor, sem passar
> pelo site, recebe a mesma recusa."

### 3:55 ~ 5:00 — Mensagem no chat → a mesma linha no banco como `enc:v1:…` → `/publico/seguranca`
*A cena mais forte do vídeo: legível no app e embaralhada no banco, lado a lado.*
*Vem da Feira: "não tem criptografia em dados sensíveis".*

**Gabriel:**
> "Outro ponto da Feira foi a falta de criptografia. Esta é a mensagem que
> acabei de enviar, e é assim que ela fica guardada no banco: embaralhada, com
> AES-256. A chave fica fora do programa."

### 5:00 ~ 6:05 — App: "Privacidade e meus dados" → baixar o arquivo → mostrar
*Vem da Feira: "nem LGPD".*

**Abner:**
> "A Feira também apontou a falta de LGPD. Agora o usuário baixa tudo o que o
> sistema guarda sobre ele, vê o consentimento que deu, e pode apagar a conta
> de verdade — o nome é substituído, não fica guardado."

### 6:05 ~ 7:05 — Painel da ONG: tela "Indicadores"
*Vem da Feira: nota 5 em "Análise de Dados e Resultados".*

**Luan:**
> "A nota mais baixa aqui foi em análise de resultados. Antes a gente só
> mostrava quantas ONGs e quantos doadores tinha — isso diz o tamanho, não diz
> se funciona. Agora acompanhamos o caminho inteiro: necessidade publicada,
> interesse, aceite e doação concluída."

### 7:05 ~ 8:05 — Site: página "Para empresas" (planos) e depois "Resultados"
**Atenção:** o enunciado diz que não é slide, é tela do sistema rodando. O
modelo de negócios é explicado **pela página do site**, não por um slide do
Lean Canvas.
*Vem da Feira: "pouco pensado para o mercado".*

**Arthur:**
> "O outro avaliador achou o projeto pouco pensado para o mercado. Nossa
> decisão: não cobrar nada sobre a doação. Quem paga é a empresa que quer usar
> a plataforma no programa social dela. ONG e doador nunca pagam — e isso está
> no ar, nesta página."

### 8:05 ~ 8:45 — Assistente Dora respondendo, com o aviso de IA visível
*Vem da Feira: critérios de compreensão e uso consciente da IA.*

**Gabriel:**
> "Usamos inteligência artificial para ajudar a ONG a se apresentar. Antes de
> enviar qualquer texto, o sistema tira e-mail, telefone e CPF. E toda tela
> avisa que a resposta é gerada por IA e pode errar."

### 8:45 ~ 9:15 — Lista de necessidades rolando no app  [EXIGÊNCIA]
*O enunciado pede comentar brevemente o que não foi concluído, e o motivo.*

**Luan:**
> "Dois itens não entraram. A lista de necessidades ainda carrega tudo de uma
> vez — hoje não incomoda, mas vai precisar ser dividida em páginas quando a
> base crescer."

**Arthur:**
> "E a conversa com ONGs de Limeira, para validar com usuários reais, depende
> de agenda de terceiros e não coube no prazo."

### 9:15 ~ 9:45 — Encerramento: os 4 integrantes na tela  [EXIGÊNCIA]
*O enunciado pede fechamento com uma frase sobre o próximo passo até a banca final.*

**Abner:**
> "Dos cinco pontos apontados na Feira, corrigimos os cinco. Até a banca final,
> nosso próximo passo é validar o sistema com três ONGs de Limeira e fechar a
> primeira empresa parceira. Obrigado!"

**Total: 9 min 45 s**

---

## Se precisar de margem

Já está dentro do limite, com 15 segundos de folga. Se na edição passar de 10
minutos, estes são os dois únicos blocos que podem encolher sem deixar nenhum
ponto dos avaliadores de fora:

- **3:20 ~ 3:55 (validação na API)** — pode cair para 20 segundos, porque a
  validação já apareceu na tela no bloco anterior. *Mas Luan perde uma fala:
  nesse caso ele assume também o bloco das 3:55, junto com o Gabriel.*
- **7:05 ~ 8:05 (mercado)** — pode cair para 40 segundos, mostrando só a página
  "Para empresas" e deixando a "Resultados" de fora.

**O que não cortar, em hipótese alguma:** os quatro blocos [EXIGÊNCIA]
(abertura, recapitulação, item não concluído e fechamento). Eles não são
demonstração — são pedidos literais do item 4.1, e a falta de qualquer um é
ponto perdido sem o vídeo nem ficar melhor.
