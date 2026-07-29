---
name: connect-ong-endereco-mapa-2026-07-29
description: "Rodada 2026-07-29 — autocomplete de endereço (OSM) no painel ONG, lat/lng no backend, mapa/Maps por coordenada exata + fix overflow e performance do desktop"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5cad0449-bb13-42c4-b449-94fc3000ffdf
  modified: 2026-07-29T15:07:03.122Z
---

Rodada de melhorias do **DESKTOP** (painel da ONG) pedida pelo usuário em 2026-07-29, mais backend e web. Tudo commitado e no ar (Render + Netlify auto-deploy). 165 testes backend verdes, `flutter analyze` limpo.

## O que foi feito (e por quê)
1. **Autocomplete de endereço estilo Maps** na edição do perfil da ONG (desktop). Antes o endereço era texto livre sem validação → ONG podia digitar rua inexistente e ninguém chegava lá. Agora, conforme digita, sugere endereços REAIS e ao escolher captura **latitude/longitude**.
   - Serviço novo: `lib/services/geocoding_service.dart` usa **Nominatim (OpenStreetMap)** — GRATUITO, sem chave, mesma família dos mapas OSM que o web já usa. Política respeitada: debounce ~550ms (≤1 req/s) + header `User-Agent` obrigatório. `countrycodes=br`.
   - Widget novo: `lib/widgets/campo_endereco_autocomplete.dart` (overlay flutuante com LayerLink/OverlayEntry, ícone ✓ quando confirmado no mapa). Gotcha corrigido: largura do dropdown lida do contexto do WIDGET, não do Overlay.
   - Na hora de salvar, se a ONG digitou mas não escolheu, tenta geocodar o texto (fallback de validação); se não achar, avisa mas deixa salvar.
2. **Backend: colunas `latitude`/`longitude` (Double) na tabela `ong`** — decisão CONSCIENTE do usuário (escolheu "adicionar 2 colunas" entre 3 opções). Changeset Liquibase **`feira-ong-lat-long`** ADITIVO e idempotente (`not columnExists` + MARK_RAN, MySQL 5.6). Expostas em `OngResponseDTO` (inclusive na LISTAGEM, são leves), `PerfilPublicoOngDTO` e aceitas no `PUT /ongs` com validação de faixa (`coordenadaValida`: dentro do planeta e ≠ 0/0). Verificado ao vivo: GET /ongs devolve `"latitude":null` para as ONGs antigas (migração rodou, nada quebrou). O banco da escola ganha as 2 colunas no próximo deploy do Render (idempotente).
3. **Web: mapa e Maps por COORDENADA EXATA.** `js/app.js` `viewMapa`: se a ONG tem lat/lng, o pino vai no local real (sem a dispersão em espiral por cidade); senão mantém o **fallback por cidade** (geocoder offline `cidades_coords.json`). Links "Abrir no Maps"/"Como chegar" (modal logado e página pública) usam `query=lat,lng` quando há coordenada.
4. **Fix do overflow "BOTTOM OVERFLOWED BY 1 PIXEL"** no card de doação PIX (`painel_ong_screen.dart` ~1949): `Column` do trailing do ListTile embrulhada em `FittedBox(scaleDown)` + `mainAxisSize.min`.
5. **Performance do desktop** (`painel_ong_screen.dart` `_carregarTudo`): os 4 blocos best-effort (atividades, selo verificada, pendências, avaliações) eram `await` em SÉRIE somando latência; agora rodam em **paralelo** com `Future.wait`, e o loop **N+1** de avaliações por doador foi paralelizado. Além disso o painel mostra o essencial ANTES (setState no meio) e preenche o resto depois.
6. **Revisão geral** (subagente): preveniu **4 possíveis overflows** de RenderFlex com texto dinâmico sem `Flexible`/`Expanded` — nome do doador ao lado das estrelas (`perfil_publico_ong_screen.dart:533`), cidade (`perfil_publico_doador_screen.dart:313`), valores da campanha (`painel_ong_screen.dart:1847`), categoria da necessidade (`perfil_publico_ong_screen.dart:510`). Varredura de crashes (`double.parse`, `.first`) → tudo já guardado por validator/`isNotEmpty`, sem risco.

Commits: backend `master` (410aad9), desktop `main` (ce5dd80 + overflow 1a8af23), web `main` (32f268d).

## Contexto de performance (importante — [[connect-ong-web-doador-plano]])
Nesta mesma sessão mediu-se que a lentidão é a distância **API (EUA/Oregon) ↔ banco (Brasil)**, não a app. Medido: de casa o **hospedado ganha do local** (local só vence na rede da escola). Criados scripts de feira (`INICIAR-FEIRA.bat` no repo web) para rodar LOCAL no dia (só vale a pena na rede da escola — testar antes). Alternativa: mover Render Oregon→Ohio (grátis, ação do usuário no painel). **Pendência humana permanece: rotacionar senha MySQL.**
