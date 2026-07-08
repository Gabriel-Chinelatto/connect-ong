---
name: connect-ong-assistente-ia
description: "Assistente de doação por IA (chatbot do doador) — Groq gratuita + fallback por regras; arquitetura, chave, contrato e como operar"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5efb506b-4e50-4863-bb56-8bc40ab1a110
---

Feature adicionada 2026-07-06 (noite, Opus): **assistente de doação por chat no app do doador**, inspirado no botão de IA do iFood. Atualiza a decisão antiga ([[connect-ong-remodel-mobile]]) de "assistente só por regras" → agora é **HÍBRIDO**: IA de verdade quando há chave, regras como fallback sempre.

## Decisão: Groq (não Gemini)
Groq tem tier GRATUITO real (sem cartão, sem cobrança por token, só rate limit). Escolhida sobre Gemini por: velocidade (LPU, resposta quase instantânea = melhor no pitch ao vivo) + limite mais que suficiente p/ feira (llama-3.1-8b-instant = 14.400 req/dia; 70b = 1.000/dia) + API OpenAI-compatível simples. Backend é AGNÓSTICO de provedor (interface `ProvedorIA`) — trocar p/ Gemini depois é implementar a interface. Console: https://console.groq.com/keys.

## Arquitetura (segura)
- Chave NUNCA no app Flutter (extraível). Fica no BACKEND. Flutter → nosso backend `/assistente` → Groq.
- Backend (commit master `af815e3`, 123 testes, ZERO dependência nova — usa `java.net.http.HttpClient` do JDK + Jackson): `service/ProvedorIA.java` (interface), `GroqService.java` (chama `POST https://api.groq.com/openai/v1/chat/completions`), `AssistenteService.java` (orquestra IA↔fallback + grounding), `AssistenteController.java`, DTOs. SecurityConfig: `POST /assistente` na whitelist (público; se logado usa a cidade do perfil). RateLimitService: 30 msgs/IP/15min (protege a cota grátis).
- Mobile (commit main `674db3f`, 67 testes): FAB "Assistente" (Icons.auto_awesome) na aba Início → `assistente_screen.dart` (chat com bolhas, 3 chips de pergunta pronta, "digitando…", cards de sugestão clicáveis → PerfilPublicoOngScreen / NecessidadeDetalheScreen). `services/assistente_service.dart`. Envia cidade do perfil + últimas ~6 trocas.

## Grounding (a IA "conhece o projeto")
O AssistenteService monta um system prompt descrevendo o Connect ONG + injeta DADOS REAIS (ONGs ativas + necessidades abertas, priorizando a cidade do doador, ~30-40 itens) no contexto. Pede resposta em JSON {resposta, sugestoes:[{tipo,id}]}. **Os ids das sugestões são REVALIDADOS contra o banco** (a IA não inventa cards; título/subtítulo vêm do banco). Se a IA não devolve JSON válido → usa o texto puro + busca simples p/ sugestões.

## Contrato do endpoint
`POST /assistente` body `{"mensagem":"...(obrigatória, max 1000)","historico":[{"papel":"user|assistente","texto":"..."}]?,"cidade":"?"}` → `{"resposta":"...","sugestoes":[{"tipo":"ONG|NECESSIDADE","id":123,"titulo":"...","subtitulo":"..."}],"modo":"ia|regras"}`. Vazia→400; excesso IP→429.

## CHAVE — como operar
- Configurada em `application-local.properties` (GITIGNORED, confirmado invisível ao git): `app.ia.groq.key=gsk_...` (o usuário gerou a dele 2026-07-06; se vazar/quiser zerar risco, gerar nova no console revoga a antiga).
- Props (defaults): `app.ia.groq.modelo=llama-3.1-8b-instant`, `.url`, `.temperatura=0.4`, `.timeout-segundos=15`, `app.ia.ratelimit.max=30`. Em prod: env `APP_IA_GROQ_KEY`.
- SEM chave OU Groq falha/timeout/429 → cai automático no modo regras (nunca quebra).

## Verificado AO VIVO (2026-07-06, API 8080 real com a chave)
- "tenho roupas e livros pra doar, não sei pra quem" (Limeira) → **modo:ia**, recomendou Lar Viva + Casa Renascer (Limeira) com necessidades reais.
- "moro em Campinas, quero ONGs perto" → **modo:ia**, ONGs de Campinas (Instituto Criança Feliz…).
- "como funciona pra doar?" → **modo:ia**, explicou o fluxo real (necessidade→match→chat→PIX/entrega).
Modo regras também provado (sem chave, H2): mesmas 3 perguntas com sugestões reais.

## 2ª rodada do assistente (2026-07-06 noite) — Dôra ganhou nome, cara, visão e localização adaptável
- **Persona "Dôra"** (de *doar*): nome + mascote SVG original (coração verde com carinha, `assets/images/dora_mascote.svg`, widget `dora_avatar.dart`); chat reescrito estilo WhatsApp (bolhas arredondadas, avatar ao lado, chips em Wrap de pílulas); botão de acesso movido do FAB (cobria Campanhas) para AO LADO DA BUSCA na Início. Boas-vindas em 1ª pessoa. Commit mobile `5d1772a`.
- **Localização adaptável**: a cidade DITA na mensagem vence a do perfil/cadastro. `detectarLocalizacaoNaMensagem` compara com as cidades reais das ONGs + mapa de bairros (`barao geraldo→Campinas`, extensível). Provado ao vivo: perfil Limeira + "barão geraldo" → recomendou Campinas.
- **Grounding query-aware/escalável**: pontua ONGs/necessidades por cidade+categoria mencionadas ANTES de cortar (35 nec/20 ongs), então com centenas de ONGs as relevantes sempre entram. Grounding é AO VIVO (findAll a cada request; add/excluir/editar reflete sem redeploy; soft-deletadas fora).
- **Cards sempre limpos**: system prompt proíbe id na prosa + `sanitizar()` remove `[id=N]`/`id=N` da resposta nos 2 modos; fallback regras devolve itens só em `sugestoes`. (Corrige o "- [id=36]..." que apareceu antes.)
- **VISÃO (analisar foto) FUNCIONA**: campo `imagemBase64` no request; modelo **`meta-llama/llama-4-scout-17b-16e-instruct`** (o `maverick` que o agente pôs dá 404 na chave real — corrigido no commit `5982f86`; scout é o ÚNICO modelo de visão no free tier, tem descontinuação anunciada → se parar, trocar `app.ia.groq.modelo-visao`, a foto degrada p/ texto). Provado ao vivo: foto de roupas+livro → Dôra descreveu e recomendou ONGs reais (modo:ia). Backend visão commit `2947ccc`.
- **Enter envia / Shift+Enter quebra linha** em TODOS os chats (assistente + match mobile `5d1772a`; chat ONG desktop `chat_ong_screen.dart` commit `30b6952`). Campos viraram multiline.
- **Chat concluído = "Histórico da conversa" (só leitura)** também no DOADOR mobile (param `concluido` no chat_screen; espelha o desktop). Backend suíte 129 testes; mobile 67; desktop 37.
- **Gerar imagem de teste p/ visão**: usei System.Drawing no PowerShell (retângulos coloridos + texto) → base64 → POST. Para diagnosticar modelo: `GET https://api.groq.com/openai/v1/models` com a chave lista os modelos REAIS da conta (foi assim que descobri maverick ausente / scout presente).

## 3ª rodada do assistente (2026-07-06 madrugada) — conversa de verdade + histórico + memória do doador
- **Modo CONVERSA (cards só quando pedidos)**: antes despejava ONGs em toda pergunta. Agora a Dôra conversa com conhecimento geral e só devolve `sugestoes` quando o usuário pede doação/ONG. `sugestoes:[]` em conversa geral e foto não-doável (backend respeita o vazio; fallback tem gate de intenção). Provado ao vivo: "capital da França?"→0 cards ("Paris!"); "quero doar roupas"→3 cards. Backend commit `28ba6d4` (135 testes).
- **VISÃO mais esperta**: descreve a foto; item doável→cards; não-doável (pessoa/paisagem)→mensagem gentil sem cards. (O que dá pra analisar: roupas/alimentos/higiene/brinquedos/livros/material escolar/utensílios/móveis/eletrônicos.)
- **Bairros/geografia**: mapa de bairros ampliado (Limeira/Campinas/Uberaba) + a IA deduz a cidade do bairro pelo próprio conhecimento. Provado: "Vila Queiroz"→Limeira.
- **USER-AWARE ("quem sou eu?/com base no que doei")**: quando logado, injeta resumo REAL do histórico do doador (categorias/ONGs/cidades via matches CONCLUIDOS + PIX + prestações), filtrado pelo id do token (`SecurityUtils.atual()`; endpoint público mas o JwtAuthFilter popula o contexto se houver token). Provado: logado como João → "Você é João Pereira... já doou Higiene... ajudou Lar Viva, Abrigo Patinhas, Bem-Estar... 2 matches, 6 PIX".
- **TÍTULO da conversa**: response ganhou campo `titulo` (2-4 palavras, gerado pela IA; fallback deriva da 1ª msg). Ex.: "Doar Roupas", "Capital da França".
- **HISTÓRICO estilo ChatGPT (mobile, commit `6d9d1f4`, 81 testes)**: `services/conversas_dora_service.dart` persiste conversas LOCAL em shared_preferences (chaves `dora_conversas_v1` + `dora_ultima_conversa_v1`; imagem salva como base64 na mensagem). AssistenteScreen multi-conversa: restaura a última ao abrir (não some mais), autosave, Drawer "Conversas" (Nova +, Buscar, fixadas no topo c/ alfinete, três-pontinhos → Fixar/Renomear/Excluir). Isolamento: cada conversa manda só o próprio histórico → não se misturam (backend é stateless). Título dedup por sufixo "(2)". **Decisão: histórico LOCAL (device), não backend** — ideal p/ TCC; cross-device precisaria de backend.
- Contrato final do /assistente: req {mensagem, historico, cidade, imagemBase64} → resp {resposta, sugestoes (vazio em conversa geral), titulo, modo}.

## 4ª rodada (2026-07-06) — polimentos do assistente + SISTEMA DE VERSÕES (changelog p/ a banca)
- **Botão voltar ao Início na Dôra**: AppBar da assistente_screen agora tem seta de voltar (`maybePop`) no leading; histórico (Icons.history→Drawer) e nova conversa (+) viraram actions à direita. Commit mobile `bdb996d`.
- **Bug dark mode no portal "Sobre o Projeto"** (`lib/web/portal_institucional_screen.dart`): o portal é SEMPRE claro (fundos brancos fixos), mas 4 títulos (cards "Como funciona"/`_CardPasso`, "O que é"/`_CardValor`, FAQ, nomes da equipe) tinham TextStyle SEM cor → herdavam a cor clara do tema ESCURO do app → texto claro sobre card branco = invisível. Fix: `color: AppColors.textPrimary` explícito nesses títulos. Lição: no portal always-light, TODO Text precisa de cor explícita.
- **SISTEMA DE VERSÕES (changelog)**: novo `lib/data/versoes.dart` (`const List<VersaoApp> kVersoesApp`, v1.7→v1.0) + seção "Versões" no fim do portal (antes do rodapé): mostra as 5 mais recentes, botão "Ver todas as versões" revela o resto; cada versão = ExpansionTile (badge + título + bullets do que foi feito); v1.7 tem selo "Atual" e abre expandida. Serve p/ a banca ver a evolução. **Versão atual = v1.7 (Assistente com IA)**. As 8 versões curadas a partir de TODA a memória: v1.0 Fundação&Match, v1.1 Confiança&Transparência, v1.2 Engajamento&Doações, v1.3 Segurança&Conformidade, v1.4 Experiência renovada, v1.5 Comunidade&Controle, v1.6 Tempo real&Segurança extra, v1.7 Assistente com IA. **Ao adicionar features grandes no futuro: incrementar (v1.8...) editando `lib/data/versoes.dart`** (só considerar versão nova após um conjunto grande de mudanças, não por commit).

## 5ª rodada (2026-07-06) — bug do Salvar Configurações (doisFatores) + Sobre o Projeto no desktop
- **BUG do Salvar Configurações (afetava OS DOIS apps)**: o backend guarda `preferencia.dois_fatores` como INTEIRO (0/1), mas o `Preferencia.toJson` dos apps enviava BOOLEAN → `PUT /usuarios/{id}/preferencias` respondia **400** ("Corpo inválido") → `_salvar` caía no catch → mostrava erro E não atualizava `_original` → `_temMudanca` seguia true → ao sair perguntava "Descartar?" mesmo após salvar. (Minha hipótese inicial de id 14 vs ongId 33 estava ERRADA — provado ao vivo por bissecção: `1`/`0`→200, `true`/`false`→400.) FIX nos 2 apps: toJson envia `doisFatores ? 1 : 0`; fromJson aceita int(0/1)/bool (antes o helper `v is bool` IGNORAVA o inteiro do GET, então o toggle 2FA nem refletia). Desktop commits `09e8fd2`; mobile `56e3fee`. **LIÇÃO: campos int-como-flag no MySQL (padrão do projeto p/ evitar boolean/BIT) — o cliente Flutter tem que enviar int, não bool.**
- **"Sobre o Projeto" + Versões no DESKTOP** (não existia): `screens/ong/sobre_projeto_screen.dart` + `data/versoes.dart` (mesmas 8 versões v1.0→v1.7), acessível pelo ícone info_outline no AppBar do painel; Versões idêntico ao mobile (5 + "Ver todas", v1.7 "Atual"), dark-safe (cores explícitas do tema). Verificado por screenshot claro+escuro. Desktop commit `a9423e9`, 38 testes.
- Portal MOBILE dark mode reconferido: já estava correto (todas as cores explícitas via AppColors); o "invisível" reportado era o desktop (sem portal) ou cache do navegador.

## 6ª rodada (2026-07-06) — corrigi a tela "Sobre o Projeto" CERTA (eu tinha editado a errada)
- **ERRO meu**: nas rodadas anteriores editei `lib/web/portal_institucional_screen.dart` (entrada WEB), mas a tela "Sobre o Projeto" que o doador abre pelo **Perfil hub** são OUTRAS: `lib/screens/about/descricao_screen.dart` ("Sobre o Connect ONG") e `lib/screens/about/integrantes_projeto_screen.dart` ("Integrantes do projeto") — ambas tinham fundo FIXO claro + textos sem cor (some no dark) e SEM Versões. **Lição: quando o usuário reclama de uma tela, achar a rota REAL (grep pelo texto exato que ele mostra no print) antes de editar — não assumir que é o portal.**
- **Fix**: reescrevi as duas telas THEME-AWARE (Scaffold/cards/texto via ColorScheme — onSurface/onSurfaceVariant/surface/outlineVariant; verde da marca AppColors.primary como acento). Agora respeitam claro E escuro (dark de verdade, texto legível). Adicionei a seção **Versões** (mesmo `kVersoesApp`) na DescricaoScreen (5 + "Ver todas", v1.7 "Atual" expandida). Provado por screenshot no dark (scratchpad/sobre-versoes.png). Commit mobile `bd498f6`.

## GOTCHA operacional
`mvnw.cmd` quebra ao FORÇAR fork com o caminho que tem espaços ("API - Chinelatto"). Para H2 use `spring-boot:test-run` com `-Dspring-boot.run.fork=false`. O `spring-boot:run` normal (porta 8080) funciona.
