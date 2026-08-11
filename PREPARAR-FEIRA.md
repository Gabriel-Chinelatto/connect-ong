# Preparar o computador da apresentação

> ## ⚠️ ESTE PLANO AINDA NÃO FOI EXECUTADO
> Ele só começa quando você disser a frase:
>
> ### **"vamos se preparar para a feira no computador de apresentação"**
>
> Aí eu executo tudo o que está aqui, na ordem, e vou te avisando. Nada disso
> mexe no que está no ar hoje: os três links hospedados continuam funcionando
> como plano B.

---

## 1. Por que está lento hoje (medido, não achismo)

Medi as mesmas telas, com **o mesmo banco de dados da escola** e a **mesma
quantidade de dados** (2.000 ONGs), mudando só onde o servidor roda:

| Tela | Servidor no Render (hoje) | Servidor rodando local | Diferença |
|---|---|---|---|
| Números do portal | 0,55s | **0,04s** | 14x |
| Ranking de transparência | *estourava o tempo limite* | **0,36s** | — |
| Feed de necessidades (909 abertas) | 1,43s | **0,16s** | 9x |
| Lista de ONGs (2.000, 1,4 MB) | 2,95s | **0,25s** | 12x |
| Perfil de uma ONG | 4,85s a 6,65s | **0,81s** | 6x a 8x |

**A lentidão não é o volume de dados nem o código: é a hospedagem gratuita.**
São três coisas somadas:

1. **O servidor tem 1/10 de um processador** e 512 MB no plano grátis do Render.
2. **O servidor está em Oregon (EUA) e o banco está na escola, em Campinas.**
   Cada consulta atravessa o continente e volta: são ~150 ms por consulta. Uma
   tela que faz 14 consultas gasta 2 segundos só indo e voltando, antes de
   processar qualquer coisa.
3. **O servidor desliga sozinho** depois de ~15 min parado, e a primeira visita
   depois disso espera ele subir (medido: de 10 a 95 segundos).

Na feira, com tudo rodando no seu notebook, essas três causas simplesmente
deixam de existir: o banco fica a 0,2 ms de distância em vez de 150 ms.

---

## 2. O plano: na feira, nada depende da internet

```
   HOJE                                    NA FEIRA
   ┌────────────┐                          ┌──────────────────────────┐
   │ navegador  │                          │      seu notebook        │
   └─────┬──────┘                          │                          │
         │ internet                        │  navegador               │
   ┌─────▼──────┐   ~150ms por consulta    │     │  (localhost)       │
   │  Render    │◄────────────────────┐    │     ▼                    │
   │  (Oregon)  │                     │    │  backend (JAR)           │
   └────────────┘                ┌────▼──┐ │     │  0,2ms por consulta │
                                 │ MySQL │ │     ▼                    │
                                 │ escola│ │  MySQL local             │
                                 └───────┘ └──────────────────────────┘
```

O conteúdo é o mesmo que está no banco agora (2.000 ONGs, 1.200 doadores, as
conversas da conta de demonstração) — eu levo uma cópia para o notebook.

---

## 3. O passo a passo que eu vou executar

| # | Passo | Tempo | Precisa de você? |
|---|---|---|---|
| 1 | Instalar o MySQL no notebook (ou Docker, se preferir) | ~15 min | **sim** (senha de administrador) |
| 2 | Copiar o banco de hoje para o notebook e conferir os números | ~10 min | não |
| 3 | Apontar o backend para o banco local (perfil `feira`), com memória folgada em vez do aperto de 512 MB do Render | ~5 min | não |
| 4 | Compilar o backend uma vez (`app.jar`), para não depender do Maven na hora | ~5 min | não |
| 5 | Compilar os dois apps Flutter para web e deixá-los servidos localmente | ~10 min | não |
| 6 | Gerar o **APK** do app do doador e instalar no seu celular (o mais convincente na banca é o app rodando no celular de verdade) | ~15 min | **sim** (cabo USB + celular) |
| 7 | Criar **um atalho só** (`INICIAR-FEIRA.bat`) que sobe banco, backend e os três frontends, e já abre as abas | ~10 min | não |
| 8 | Criar o **aquecimento**: um script que faz login e visita as telas principais antes da banca chegar, para nenhuma tela ser a "primeira vez" | ~10 min | não |
| 9 | Ligar o **Modo Feira** na versão local (as credenciais aparecem na tela de login e o visitante entra sozinho no estande) | ~2 min | não |
| 10 | **Testar com o Wi-Fi desligado** e cronometrar cada tela | ~15 min | não |

Total estimado: **cerca de 1h30**, feito de uma vez, com você por perto só nos
passos 1 e 6.

---

## 4. As três coisas que ainda precisam de internet (e o que fazer)

| O que | Se tiver internet | Se não tiver |
|---|---|---|
| **Mapa** (as imagens dos mapas vêm do OpenStreetMap) | funciona normal | posso deixar as imagens da região de Limeira/Campinas guardadas no disco antes — me peça isso junto |
| **Autocomplete de endereço** (cadastro de ONG) | funciona normal | o campo continua aceitando digitação livre, só não sugere |
| **IA** (assistente de doação e o chat "Sobre o Desenvolvimento") | funciona normal | cai sozinho no modo por regras, que responde offline |

**Me diga se a feira terá internet** (mesmo que seja o 5G do seu celular) que eu
ajusto o plano. Se a resposta for "não sei", eu preparo para os dois casos.

---

## 5. O que fica pronto no fim

- Um atalho na área de trabalho: clicou, tudo sobe e abre.
- Três telas abertas: site do doador, app do doador e painel da ONG.
- O app no seu celular, para passar de mão em mão no estande.
- Uma folha impressa com as contas de demonstração e o roteiro de 3 minutos.
- Os links hospedados continuam no ar, como plano B, caso o notebook falhe.

---

## 6. Riscos e como cada um está coberto

| Risco | Cobertura |
|---|---|
| Notebook não liga / trava | Os três links hospedados continuam funcionando de qualquer máquina |
| MySQL local não instala (política da escola, antivírus) | Plano B: banco da escola pela rede + backend local (ainda ~3x mais rápido que hoje) |
| Sem internet e sem mapa | O mapa é uma tela entre muitas; o roteiro não depende dele |
| Alguém mexer nos dados durante a feira | O banco é local: qualquer bagunça se resolve restaurando a cópia em 2 minutos |
| Celular sem bateria | O app roda igual no navegador do notebook |

---

*Escrito em 11/08/2026, com as medições feitas no mesmo dia. Guia de como
apresentar (links, contas, plano B) continua em [COMO-MOSTRAR.md](COMO-MOSTRAR.md).*
