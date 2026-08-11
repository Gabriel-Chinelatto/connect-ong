---
name: connect-ong-varredura-2026-08-10
description: Rodada de bugs + varredura geral de 10/08/2026 (a ONG nao conseguia salvar o perfil, IA do dev sem conhecimento real, mapa/comparador/duplo-clique na web, validacao de campos e aviso de alteracoes nao salvas)
metadata:
  type: project
---

# Rodada de 10/08/2026 — bugs do teste com o grupo + varredura geral

Contexto: o usuario apresentou ao grupo (deu certo), listou o que faltava e pediu
tambem uma **varredura geral** e uma **varredura de todos os campos dos 3 apps**
(validacao, salvamento e aviso de alteracoes nao salvas). Faltava menos de um mes
para a FECITEC.

Commits: backend `ee93dc5`, `0f2316d`, `35d4667` · desktop `0851ebf` (+ `91810a2`,
`afa58ee`) · mobile `8024f70` · web `5e6e9cf`, `b94616a`.
Estado final: **backend 179 testes · doador 96 · painel 50**, analyze limpo nos
dois Flutter, web verificada sem erro de console.

## 🔴 O bug mais grave: a ONG nao conseguia salvar NADA no perfil

`GET /ongs/{id}` **nao devolve o e-mail** (privacidade). O painel carregava o
campo vazio e o reenviava como `""` no PUT. Como a entidade `Ong` tem
`@NotBlank @Email`, a violacao estourava no flush e virava **500** — nem
telefone, nem cidade, nem descricao eram salvos.

Reproduzido contra a API de producao ANTES de corrigir (PUT com e-mail vazio =
500; com e-mail preenchido = 200).

Correcao em duas pontas: no `ONGService.atualizar`, nome e e-mail so sao
sobrescritos quando vem PREENCHIDOS (mesmo padrao ja usado em capa/endereco);
no `ong_service.dart` do painel, o e-mail so e enviado quando a tela realmente o
tem. Travado em `OngAtualizacaoParcialTest` (4 casos).

⚠️ **Cuidado com o nome do arquivo `ONGService.java`**: o git rastreia com ONG
maiusculo, mas o Windows nao diferencia caixa — editar usando `OngService.java`
RENOMEIA o arquivo e quebra a compilacao ("class ONGService is public, should be
declared in a file named ONGService.java"). Aconteceu nesta sessao.

## Painel da ONG (desktop)

- **UF vazia com cidade preenchida**: cadastros antigos guardavam so "Limeira",
  sem o " - SP". Agora `ufDaCidade()` deduz a UF quando o nome existe em UM unico
  estado; havendo homonimas (ex.: "Bom Jesus" no PI e no RS) fica em branco de
  proposito. Trocar a UF so apaga a cidade se ela nao pertencer ao novo estado
  (antes apagava sempre). O dropdown ganhou `key` porque `initialValue` sozinho
  so vale na primeira construcao.
- **Clicar na sugestao de endereco nao fazia nada** (bug classico, vale lembrar):
  ao tocar na sugestao o campo perdia o foco PRIMEIRO, o ouvinte de foco fechava
  o overlay e o toque morria junto. Solucao: `Listener/onPointerDown` no item da
  lista, que chega antes da troca de foco. A busca tambem passou a ser ancorada
  na cidade/UF do formulario e reordenada por relevancia (o Nominatim ordena por
  "importancia" do lugar e jogava a capital para cima).
- **Chat "Sobre o Desenvolvimento"**: usava cores fixas claras — no modo noturno
  a tela continuava branca e o texto DIGITADO sumia (fundo claro fixo + cor da
  letra vinda do tema). Agora tudo do `ColorScheme` e `style` explicito no campo.

## IA "Sobre o Desenvolvimento" — agora responde de verdade

Dois problemas medidos em producao:
1. O documento de grounding era raso (72 linhas, so o "o que"): "como a api
   valida o token jwt?" recebia "nao ha informacoes suficientes".
2. O fallback por regras aceitava QUALQUER coincidencia de palavra: "qual seu
   time de futebol favorito?" casava com "favoritos" e devolvia o historico de
   versoes inteiro.

`resources/dev/conhecimento_dev.md` foi reescrito com o COMO (camadas e pacotes,
mapa dos endpoints, fluxo do match PENDENTE→ACEITO/RECUSADO→CONCLUIDO, JWT 12h +
refresh 7d, autorizacao por dono, rate limit 5/15min, Liquibase com 58
changesets e por que nao Flyway, a regra dos 600ms e o N+1, score de
transparencia, PIX em 2 fases, Groq/grounding/fallback, frete IBGE+Haversine,
Nominatim, hospedagem e testes) — **tudo conferido no codigo, sem inventar**.
O `systemPrompt` ganhou tres regras (recusar fora de escopo em uma frase,
fidelidade ao documento, formato) e o fallback exige relevancia minima
(`ESCORE_MINIMO`). Travado em `AssistenteDevEscopoTest` (5 casos).

💡 Como testar rapido se a IA esta no modo IA ou no modo regras: o tempo de
resposta denuncia (~1,2s = IA real; ~0,3s = fallback por regras).

## Web

- **Barra de busca do mapa invisivel no escuro**: o CSS mapeava so **2 das 9**
  variantes de fundo branco translucido usadas no codigo. `bg-white/95` nao
  estava mapeada → fundo branco com texto claro por cima. Todas mapeadas agora.
  **Regra para o futuro: ao usar `bg-white/NN` nova, mapear no tema escuro.**
- **Mapa escuro ilegivel**: o tile `dark_all` do CartoDB era escuro demais. Os
  dois temas usam o mesmo mapa (Voyager) e o escuro apenas o escurece por filtro
  CSS (`.tema-escuro .leaflet-tile`).
- **Botao de centralizar "nao funcionava"**: so repintava com o filtro atual —
  com busca ativa contrariava o proprio nome e, sem filtro, nada mudava. Agora
  limpa o filtro e reenquadra tudo.
- **Comparador "nao adicionava" a ONG**: aguardava o perfil chegar da API ANTES
  de desenhar; como a chamada leva de 0,7s a alguns segundos, o clique parecia
  nao fazer nada. Agora desenha na hora com esqueleto de carregamento.
- **Duplo clique gerava a acao duas vezes** (ex.: dois cartoes de impacto).
  Trava central: o handler global ja devolvia a promessa de cada acao, entao
  passou a marcar o elemento como ocupado, ignorar novos cliques e mostrar
  "carregando...". Botoes com handler proprio usam `ligarAcao()`.

## Varredura de campos (pedido explicito do usuario)

- **Aviso de alteracoes nao salvas**: existia SO nas telas de Configuracoes. Nos
  3 apps, editar perfil e sair perdia tudo em silencio. Virou componente
  compartilhado (`widgets/confirmar_saida.dart` no desktop,
  `widgets/common/confirmar_saida.dart` no mobile) que adotou a versao MELHOR (a
  das Configuracoes), com tres saidas: continuar editando, descartar ou **SALVAR
  na hora**. Caso importante travado em teste: **se o salvamento falhar, a pessoa
  NAO sai** (senao perderia o trabalho achando que salvou).
  Na web: `data-avisar-saida` nos formularios de edicao; fechar pelo X ou por
  fora pede confirmacao, mas o `fecharModal()` chamado pelo codigo apos salvar
  nao pergunta. Busca e chat ficaram de fora de proposito.
- **Limites iguais aos dos DTOs do backend** (antes o erro so aparecia ao
  salvar): perfil da ONG (nome 100, telefone 20, descricao 1000, que nao tinham
  NENHUM), necessidade (titulo 150 **e minimo 3** — o formulario aceitava 1-2
  letras e falhava no envio), campanha (titulo 150, descricao 255), cadastro da
  ONG (nome 120/min 2, e-mail 150, telefone 20, CNPJ 20, descricao 1000) e 9
  campos da web. Contador so aparece a partir de 80% do limite.
  O app do doador ja estava correto.

## 🔎 Achado da varredura: erro do cliente virava 500

Testando a API de producao rota a rota, as **quatro formas de errar a chamada**
caiam no generico "Ocorreu um erro inesperado no servidor":

| Erro | Antes | Agora |
|---|---|---|
| Parametro obrigatorio ausente | 500 | **400** dizendo qual faltou |
| Tipo invalido (`/ongs/abc`) | 400 ✓ | 400 |
| Rota inexistente | 500 | **404** |
| Metodo HTTP errado | 500 | **405** |

O ultimo caso era o mais enganoso: `GET /usuarios/me` respondia 500 nao por rota
inexistente, mas porque `/usuarios/{id}` **existe e so aceita DELETE**.
Handlers no `GlobalExceptionHandler` + `TransactionSystemException` (o Spring
embrulha a ConstraintViolationException do commit, que escapava e virava 500 —
foi assim que o bug do perfil da ONG apareceu). `ErrosDeEntradaTest`, 5 casos.
**Validado em producao apos o deploy.**

⚠️ Ao testar esses casos com curl, **mande o token**: sem ele o filtro JWT
responde 401 antes de chegar no roteamento, e parece que a correcao nao subiu.

## Pendencias que continuam abertas (nao sao codigo)

1. **Emulador Android do notebook** para a feira — o usuario adiara para perto da
   data. Esta maquina **nao tem Android SDK**. No emulador, `localhost` e o
   proprio celular virtual: usar `--dart-define=API_BASE=http://10.0.2.2:8080`
   para backend local. Sugerido tambem gerar APK e usar celular real como
   principal. Cuidado com o Avast/PKIX ([[ambiente-java-avast-tls]]).
2. **Pasta solta `connect-ong/connect-ong-web/`** — clone com um commit de
   landing page que NAO existe no GitHub; nada usa. Ofereci apagar 3x, sem
   resposta.
3. **UptimeRobot** para a API nao hibernar (o ping por GitHub Actions nao
   resolve — ver [[connect-ong-hospedagem-2026-08-05]]).
4. **Rotacionar a senha do MySQL** (pendencia antiga).

Ver [[connect-ong-hospedagem-2026-08-05]] e [[connect-ong-feedback-app-2026-08-03]].
