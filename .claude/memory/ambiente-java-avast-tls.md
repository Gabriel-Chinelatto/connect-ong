---
name: ambiente-java-avast-tls
description: "Gotcha: Avast intercepta TLS no notebook do usuario -> ferramentas Java (sdkmanager/Gradle/Maven) falham com PKIX; fix = importar a CA do Avast no cacerts"
metadata:
  node_type: memory
  type: reference
  originSessionId: 29811329-d22b-44a3-85f0-3e1c2637d9eb
---

No notebook `gabri` (ver [[connect-ong-notebook-fecitec]]) o **Avast Antivirus faz varredura HTTPS** (man-in-the-middle local): troca o certificado dos sites por um assinado pela CA "**Avast Web/Mail Shield Root**".

**Sintomas:**
- **curl/winget:** erro de **revogacao** (`schannel: CRYPT_E_NO_REVOCATION_CHECK`) porque a rede nao alcanca o servidor de CRL/OCSP. Fix: `curl --ssl-no-revoke ...` (winget: usar `--source winget` p/ evitar a fonte `msstore` que da erro de certificado).
- **Ferramentas Java** (Android `sdkmanager`, Gradle, e Maven em downloads NOVOS): `javax.net.ssl.SSLHandshakeException: PKIX path building failed: unable to find valid certification path`. Motivo: o Java usa o **proprio truststore** (`cacerts`), que NAO conhece a CA do Avast (o Windows conhece, por isso curl/winget passam pelo schannel).

**FIX DEFINITIVO (feito 2026-06-26 no Corretto 21):**
1. Exportar a CA do Avast do repositorio do Windows:
   `Get-ChildItem Cert:\LocalMachine\Root | ? {$_.Subject -like '*Avast*'}` → `.Export('Cert')` p/ um `.cer`.
2. Importar no cacerts do JDK usado:
   `keytool -importcert -noprompt -trustcacerts -alias avast-root -file avast-root.cer -keystore "<JDK>\lib\security\cacerts" -storepass changeit`
   (Feito no `C:\Users\gabri\.jdks\corretto-21.0.3`. O JBR do Android Studio em Program Files deu "Acesso negado" — contornado rodando `sdkmanager`/Gradle com `JAVA_HOME=corretto-21`, que ja tem a CA.)

**Por que importa p/ o projeto:** sem isso, NAO da p/ instalar o Android SDK/emulador nem fazer build Android offline-da-CA; e o `mvn` so funcionou de cara porque as deps ja estavam no `.m2`. Se aparecer PKIX em qualquer passo Java nesta maquina, a causa e essa. (O Maven do projeto: usar o permanente em `C:\Users\gabri\tools`, NAO o `./mvnw`.)
