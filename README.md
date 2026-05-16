# 📱 Connect ONG - Mobile

O **Connect ONG** é um aplicativo mobile desenvolvido em **Flutter** que serve como ponte entre organizações sem fins lucrativos (ONGs) e pessoas que desejam realizar doações ou voluntariado.

## 🚀 Funcionalidades Atuais

- **Autenticação:** Cadastro e login de usuários (Doadores ou Receptores).
- **Gerenciamento de ONGs:** Criação, edição, listagem e exclusão de ONGs (CRUD completo).
- **Sistema de Doações:** Registro de intenções de doação e acompanhamento.
- **Busca Avançada:** Filtros para encontrar instituições por cidade ou causa.

## 🛠️ Tecnologias e Dependências

- **Framework:** [Flutter SDK ^3.7.0](https://flutter.dev)
- **Linguagem:** Dart
- **Comunicação API:** [http](https://pub.dev/packages/http)
- **Persistência Local:** [shared_preferences](https://pub.dev/packages/shared_preferences) para gestão de sessão.
- **UI:** Material Design 3 com ícones customizados.

## 📁 Estrutura de Pastas

```text
lib/
├── doador/      # Telas e widgets específicos para o perfil doador
├── receptor/    # Telas e widgets específicos para o perfil receptor (ONGs)
├── models/      # Classes de modelo de dados (UsuarioLogado, etc)
├── services/    # Lógica de integração com API (Auth, Session)
├── widgets/     # Componentes reutilizáveis de interface
└── main.dart    # Ponto de entrada e decisor de splash/sessão
```

## ⚙️ Configuração e Execução

1. Certifique-se de ter o Flutter instalado (`flutter doctor`).
2. Clone o repositório.
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Configure a URL da API no arquivo `lib/services/auth_service.dart` (padrão: `10.0.2.2` para emulador Android).
5. Execute o projeto:
   ```bash
   flutter run
   ```

## 📝 Notas de Desenvolvimento
O aplicativo utiliza `setState` para gerenciamento de estado local e integra-se via JSON com a API REST Connect ONG.
