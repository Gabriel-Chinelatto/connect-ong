# Arquitetura — App Mobile do Doador (Connect ONG)

> Documentação interna de arquitetura deste aplicativo Flutter.
> Tudo em português, conforme padrão do projeto.

## Visão geral do produto

**Connect ONG** é uma plataforma que conecta **doadores** a **ONGs**. O ecossistema é
composto por três frontends e um backend compartilhado:

| Componente | Tecnologia | Papel |
|------------|------------|-------|
| **App mobile (este repositório)** | Flutter | Aplicativo do **DOADOR** |
| Painel desktop | Flutter | Painel administrativo da **ONG** |
| Portal web | Flutter Web | Vitrine institucional pública |
| API | Spring Boot | Regras de negócio + REST |
| Banco | MySQL | Persistência |

Este repositório é **exclusivamente o app do doador**. (No mesmo build, ao rodar na
web, a entrada é o portal institucional público — ver `lib/main.dart` —, mas o foco do
produto mobile é o doador.)

### Hero feature (fluxo de match)

1. O **doador** demonstra interesse em uma **necessidade** publicada por uma ONG.
2. A **ONG** aceita o interesse → forma-se um **match**.
3. Com o match aceito, o **chat** entre doador e ONG é habilitado.

Ou seja: o chat só abre **após o match ser aceito**. Esta regra atravessa as telas
de matches e de chat.

## Camadas do aplicativo

O app segue uma separação simples em três camadas:

```
  UI (telas)            lib/doador/**, lib/pages/**, lib/screens/**, lib/web/**, lib/widgets/**
       │  chama
       ▼
  Serviços              lib/services/**   (package http -> API REST)
       │  desserializa
       ▼
  Modelos               lib/models/**     (fromJson / toJson)
```

- **UI** — Telas (em `lib/doador/`) e widgets reutilizáveis (`lib/widgets/`). Cada tela
  declara o que faz e a regra de negócio relevante no cabeçalho `///` da sua classe.
- **Serviços** (`lib/services/`) — Cada serviço encapsula um conjunto de endpoints da API,
  usando o pacote `http`. Recebem/devolvem **modelos**, escondendo o detalhe de rede da UI.
- **Modelos** (`lib/models/`) — Objetos de domínio desserializados do JSON da API via
  `fromJson` (e serializados via `toJson` quando precisam ser persistidos/enviados).

### Gerência de estado

A gerência de estado é deliberadamente simples: **`StatefulWidget` + `setState`**.
Não há Provider/Bloc/Riverpod para o fluxo de telas. A exceção é o
`ConfigController` (um `ChangeNotifier`/`Listenable`) que centraliza as preferências
de aparência/acessibilidade e é observado pelo `MaterialApp` em `lib/main.dart`.

## Tratamento de dados e de sessão

### Autenticação (JWT)

A API **exige autenticação JWT** em todos os endpoints protegidos. O ciclo de vida do
token é gerenciado pelo `ApiService` (`lib/services/api_service.dart`), que funciona como
armazém central do token:

1. **Login** — `AuthService.login()` chama `POST /usuarios/login`. Em sucesso, extrai o
   `accessToken` da resposta e o entrega ao `ApiService.setToken()`, que o mantém em
   memória **e** o persiste no `SharedPreferences`.
2. **Requisições autenticadas** — Todo serviço monta os cabeçalhos via
   `ApiService.jsonHeaders()` (POST/PUT com corpo JSON) ou `ApiService.authHeaders()`
   (GET/DELETE). Ambos injetam o header:

   ```
   Authorization: Bearer <accessToken>
   ```

3. **Startup** — Em `main()`, antes de exibir a UI, chama-se `ApiService.carregarToken()`
   para recarregar o token salvo, mantendo a sessão anterior autenticada.
4. **Logout** — `SessionService.logout()` remove o usuário salvo e chama
   `ApiService.setToken(null)`, **limpando o token** (memória + armazenamento). A partir
   daí as requisições deixam de ser autenticadas.

Como cada requisição carrega o token do usuário, **cada usuário acessa apenas os
próprios dados**.

### Sessão do usuário

O `SessionService` persiste o `UsuarioLogado` (id, nome, e-mail, tipo) como JSON no
`SharedPreferences`. No startup, o `SplashDecider` (`lib/main.dart`) decide a rota
inicial: sem sessão → tela de login; com sessão → carrega preferências e abre a home
do doador.

### Codificação de respostas

As respostas da API são decodificadas com `utf8.decode(response.bodyBytes)` antes do
`jsonDecode`, garantindo que acentuação e caracteres especiais (comuns em português)
sejam preservados corretamente.

### Polling do chat

A tela de chat (`lib/doador/chat_screen.dart`) usa **polling a cada 2 segundos**
(`Timer.periodic`) para buscar novas mensagens. É uma abordagem simples e confiável,
que funciona em qualquer plataforma sem depender de WebSocket/push.

## Endpoint base (configuração)

A URL da API é centralizada em **`ApiService.baseUrl`** (`lib/services/api_service.dart`).
Todos os serviços a referenciam, então trocar de ambiente é uma alteração em um único
ponto.

```dart
// CHROME / WINDOWS / DESKTOP (desenvolvimento)
static const String baseUrl = 'http://localhost:8080';

// ANDROID EMULATOR (alternativa em desenvolvimento)
// static const String baseUrl = 'http://10.0.2.2:8080';
```

> **Observação (dev):** em desenvolvimento a base aponta para `http://localhost:8080`
> (o backend Spring Boot rodando na máquina). No **emulador Android**, `localhost` se
> refere ao próprio emulador, então usa-se `http://10.0.2.2:8080` (alias do host). Em
> produção, este valor deve apontar para o endereço público da API.

## Tema e identidade visual

- `lib/theme/app_colors.dart` — paleta da marca (verde `0xFF0A8449` como cor primária),
  fonte única de verdade para cores.
- `lib/theme/app_theme.dart` — temas claro/escuro, com variações de acessibilidade
  (fonte para dislexia, alto contraste).
- `lib/config/config_controller.dart` — preferências do usuário (tema, escala de fonte,
  dislexia, alto contraste), aplicadas globalmente no `MaterialApp`.

## Mapa de diretórios

```
lib/
├── main.dart                # bootstrap: carrega token e decide rota inicial
├── config/                  # ConfigController (preferências/acessibilidade)
├── models/                  # objetos de domínio (fromJson/toJson)
├── services/                # acesso à API REST (http + JWT)
│   └── api_service.dart     # baseUrl + armazém do token + headers de auth
├── doador/                  # telas do app do doador
├── pages/                   # login
├── screens/                 # telas auxiliares (sobre, legal)
├── web/                     # portal institucional (build web)
├── theme/                   # cores e temas da marca
├── utils/                   # utilitários (transições de página)
└── widgets/                 # componentes reutilizáveis (botões, cards, inputs, feedback)
```
