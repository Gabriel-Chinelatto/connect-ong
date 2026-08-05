# Como mostrar o Connect ONG (PC da escola, banca, feira)

Guia curto para **apresentar** o projeto. Nada aqui exige instalar programa,
clonar repositório ou abrir o IntelliJ.

---

## 1. O jeito simples: só o navegador

Abra os três endereços. É tudo que precisa em um PC que não é o seu:

| O que é | Endereço |
|---|---|
| Site do doador (HTML puro) | https://connectong.netlify.app |
| App do doador (Flutter web) | https://gabriel-chinelatto.github.io/connect-ong/ |
| Painel da ONG (Flutter web) | https://gabriel-chinelatto.github.io/connect-ong-desktop/ |

### ⏰ O único cuidado importante

A API roda no plano **gratuito** do Render, que **desliga o servidor depois de
~15 minutos sem acesso**. A primeira visita depois disso espera o servidor
subir — medido: **de 10 a 95 segundos**.

**Antes de apresentar, abra qualquer um dos links (ou o endereço abaixo) e
espere carregar.** Depois disso tudo fica rápido.

```
https://connect-ong-api.onrender.com/publico/estatisticas
```

Deve aparecer uma linha com os números do projeto. Se aparecer, está quente.

### Contas de demonstração

Nas versões publicadas as credenciais **não aparecem na tela** de propósito
(qualquer pessoa poderia entrar e alterar os dados). Tenha-as à mão:

| Perfil | E-mail | Senha |
|---|---|---|
| Doador | `demo.joao@connectong.com` | `demo123` |
| ONG (painel) | `demo.larviva@connectong.com` | `demo123` |

Se quiser que apareçam na tela de login (útil no estande, para o visitante
entrar sozinho), ligue **Modo Feira** em Configurações.

---

## 2. Se a internet da escola falhar: rodar tudo local

Só vale a pena na **sua** máquina, que já tem tudo instalado. É mais rápido
(a API responde em ~0,02s em vez de ~0,7s) e não depende do Render.

Precisa de: JDK 21, Flutter e o arquivo `application-local.properties` com a
senha do banco (ele **não** está no Git — está em
`C:\Users\...\CONNECT-ONG-SEGREDOS.txt`).

```bash
# 1) Backend (porta 8080)
cd "connect-ong-api/API - Chinelatto - att2/API - Chinelatto/API - Chinelatto"
./mvnw spring-boot:run -Dspring-boot.run.profiles=local

# 2) App do doador (porta 5000)
cd connect-ong
flutter run -d chrome --web-port=5000 --dart-define=API_BASE=http://localhost:8080

# 3) Painel da ONG (porta 5001)
cd "connect_ong - Desktop"
flutter run -d chrome --web-port=5001 --dart-define=API_BASE=http://localhost:8080

# 4) Site do doador (porta 8090, com proxy para a API local)
cd connect-ong-web-main
python serve.py 8090 http://localhost:8080
```

⚠️ **Continua precisando de internet**: o banco de dados fica no servidor da
escola (`143.106.241.3`). O que some é a dependência do Render.

⚠️ Ao matar um `flutter run`, o processo `dartvm` **continua segurando a
porta**. Se der "Failed to bind web development server", libere assim:

```powershell
Get-NetTCPConnection -LocalPort 5000 -State Listen |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```

---

## 3. Se algo der errado na hora

| Sintoma | O que é | O que fazer |
|---|---|---|
| Primeira tela demora muito | Servidor hibernando | Esperar (até ~1,5 min). O app avisa que está iniciando. |
| "O servidor está fora do ar (erro 502)" | A aplicação caiu no Render | Abrir o painel do Render e ver **Logs**; um novo deploy costuma resolver. |
| Telas vazias, tudo zerado | A API não respondeu | Testar o endereço de estatísticas acima. |
| Site abre mas nada carrega | Front no ar, API não | Mesmo caso acima — o problema é a API, não o site. |

Existe um alarme automático: um GitHub Action testa a API de tempos em tempos e
**manda e-mail quando ela cai**. Ele avisa, mas não conserta.

---

## 4. O que NÃO é necessário

- ❌ Abrir o IntelliJ para apresentar (só para desenvolver o backend).
- ❌ Clonar os repositórios no PC da escola.
- ❌ Instalar Flutter, JDK ou Maven no PC da escola.
- ❌ Emulador de Android.
