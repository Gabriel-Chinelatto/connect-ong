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

### 🤖 Confira também se a IA está ligada

A IA nunca dá erro na tela: quando ela não responde, o assistente cai sozinho
no modo por regras e aparece só um selo discreto **"Modo básico"** embaixo da
resposta. Foi assim que ela passou dias fora do ar sem ninguém notar (a Groq
tinha aposentado o modelo que usávamos).

Abra este endereço — dá para conferir do celular, em pé no estande:

```
https://connect-ong-api.onrender.com/ia/status?ping=true
```

| O que vier | O que significa |
|---|---|
| `"ping":"ok"` | IA respondendo. Pode apresentar. |
| `"chaveConfigurada":false` | Falta a variável `APP_IA_GROQ_KEY` no Render → **tudo** fica em "Modo básico". |
| `"ping":"falhou"` | Veja `ultimoErro`: `404` = modelo aposentado (trocar em `app.ia.groq.modelo`), `429` = cota do minuto (esperar 1 min). |

A cota gratuita é de **8.000 tokens por minuto por modelo**. A API usa três
modelos em cadeia justamente para a fila do estande não esbarrar nisso.

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

⚠️ **Se o site (8090) abrir com "HTTP ERROR 501"**: alguém já estava naquela
porta e é **ele** que está respondendo o navegador, não o site. No Windows o
`serve.py` conseguia ligar por cima de outro programa **sem dar erro nenhum** —
ele avisava "Connect ONG em http://localhost:8090" como se estivesse tudo bem.
Corrigido: agora o `serve.py` recusa subir e mostra quem está ocupando a porta.
Basta ler a mensagem dele na janela preta e rodar o comando que ele sugere
(mesmo comando acima, trocando 5000 por 8090).

### 📱 E se eu quiser mostrar no emulador do Android?

Nada a configurar: o emulador usa a internet do próprio computador e o app já
aponta para a API publicada. Só **acorde a API antes** (link lá em cima).

Se quiser o emulador falando com o **backend local**, o endereço `localhost`
não serve — dentro do emulador ele é o próprio Android. Use `10.0.2.2`, que é
o apelido do PC visto de dentro do emulador:

```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:8080
```

---

## 3. Se algo der errado na hora

| Sintoma | O que é | O que fazer |
|---|---|---|
| Primeira tela demora muito | Servidor hibernando | Esperar (até ~1,5 min). O app avisa que está iniciando. |
| "O servidor está fora do ar (erro 502)" | A aplicação caiu no Render | Abrir o painel do Render e ver **Logs**; um novo deploy costuma resolver. |
| Telas vazias, tudo zerado | A API não respondeu | Testar o endereço de estatísticas acima. |
| Site abre mas nada carrega | Front no ar, API não | Mesmo caso acima — o problema é a API, não o site. |
| Assistente responde curto/genérico com o selo **"Modo básico"** | A IA não respondeu e caiu no fallback por regras | Abrir `/ia/status?ping=true` (seção 1). Se for `429`, esperar 1 minuto: é a cota gratuita por minuto. |
| Site local (8090) abre com **HTTP ERROR 501** | Outro programa já está naquela porta | Fechar a janela do site, liberar a porta 8090 (seção 2) e rodar o `serve.py` de novo. |

Existe um alarme automático: um GitHub Action testa a API de tempos em tempos e
**manda e-mail quando ela cai**. Ele avisa, mas não conserta.

---

## 4. O que NÃO é necessário

- ❌ Abrir o IntelliJ para apresentar (só para desenvolver o backend).
- ❌ Clonar os repositórios no PC da escola.
- ❌ Instalar Flutter, JDK ou Maven no PC da escola.
- ❌ Emulador de Android.
