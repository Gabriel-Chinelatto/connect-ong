# Roteiro de demonstração — Connect ONG (FECITEC)

Guia rápido para apresentar o projeto de forma fluida e convincente.

## Antes de começar (preparação)
1. Suba o **backend** (Spring Boot na porta 8080).
2. No **app Desktop (ONG)**, faça login e vá em **Configurações → Modo Feira → "Carregar dados demonstrativos"**.
   - Isso popula o sistema com 4 ONGs, 3 doadores, necessidades, um match com chat, prestação de contas, avaliações e doações PIX.
   - É **idempotente**: pode clicar à vontade que não duplica.
3. Contas de exemplo (senha **demo123**):
   - ONG: `demo.larviva@connectong.com`
   - Doador: `demo.joao@connectong.com`

## Roteiro sugerido (≈ 5 min)

### 1. Portal Web (a "vitrine")
- Abra o **build web** (portal institucional).
- Mostre: missão, **estatísticas públicas ao vivo** (transparência), ODS, como funciona, equipe e FAQ.
- Mensagem: "é a porta de entrada pública e transparente da plataforma".

### 2. App do Doador (mobile)
- Faça login como `demo.joao`.
- Mostre o **feed de necessidades** (busca, filtros, urgência).
- Demonstre **demonstrar interesse** numa necessidade.
- Mostre **doação via PIX** (gera comprovante).
- Abra o **chat** de um match aceito e os **meus matches**.

### 3. App da ONG (desktop)
- Faça login como `demo.larviva`.
- Mostre o **painel da ONG**: necessidades publicadas, interesses recebidos.
- **Aceite um interesse** (vira match) e responda no **chat**.
- Publique uma **prestação de contas**.
- Mostre as **notificações** chegando.

### 4. Diferenciais técnicos (fechar com chave de ouro)
- **API RESTful** documentada (Swagger em `/swagger-ui.html`).
- **JWT** (tokens em `/auth/me` e `/auth/refresh`).
- **Auditoria** (`/audit-logs`) e **transparência** (`/publico/estatisticas`).
- **Migrations** (Liquibase) + **CI/CD** (GitHub Actions) + **Docker**.

## Dica
Se algo der errado ao vivo, o **Modo Feira** recria o cenário em 1 clique.
Tenha o backend e os 3 frontends já abertos antes de começar.
