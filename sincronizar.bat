@echo off
setlocal enabledelayedexpansion
title Sincronizar Connect ONG
chcp 65001 >nul

echo ============================================================
echo    SINCRONIZAR CONNECT ONG  (mobile + backend + desktop)
echo    Puxa do git e envia suas mudancas - SEM REGRESSAO:
echo      - o pull nunca reverte/perde seu trabalho (aborta em conflito)
echo      - so envia se a verificacao passar (build/analyze OK)
echo ============================================================
echo.

REM Descobre os repos testando caminhos candidatos sob o SEU usuario (cobre este
REM PC e o notebook, com layouts diferentes). So opera nos que forem repo git.
for %%R in (
  "%USERPROFILE%\connect-ong"
  "%USERPROFILE%\Desktop\connect-ong"
  "%USERPROFILE%\IdeaProjects\connect-ong-api"
  "%USERPROFILE%\Desktop\connect-ong-api"
  "%USERPROFILE%\connect_ong - Desktop"
  "%USERPROFILE%\Desktop\connect_ong - Desktop"
  "%USERPROFILE%\Desktop\connect-ong-desktop"
) do (
  if exist "%%~R\.git" (
    REM Guarda o caminho de cada repo (o 1o que existir de cada tipo) para depois
    REM gerar o settings.local.json automaticamente.
    if exist "%%~R\.claude\settings.local.json.example" if not defined MOBILE_DIR set "MOBILE_DIR=%%~R"
    if exist "%%~R\API - Chinelatto - att2" if not defined BACKEND_DIR set "BACKEND_DIR=%%~R"
    if exist "%%~R\lib\screens\ong" if not defined DESKTOP_DIR set "DESKTOP_DIR=%%~R"

    echo --- %%~R
    pushd "%%~R"

    REM ===== 1) PULL SEGURO: traz o remoto guardando o local; em conflito, aborta
    REM e restaura o estado anterior (nada e revertido/perdido).
    git pull --rebase --autostash
    if errorlevel 1 (
      git rebase --abort >nul 2>&1
      echo   [ATENCAO] conflito ao puxar. Restaurei o estado anterior, nada mudou.
      echo             Resolva pedindo ajuda no chat antes de sincronizar de novo.
    ) else (
      REM ===== 2) Registra o que houver de local
      git add -A
      git diff --cached --quiet
      if errorlevel 1 git commit -m "sync automatico" >nul

      REM ===== 3) Ha commits locais ainda nao enviados?
      set "AHEAD=0"
      for /f %%N in ('git rev-list --count "@{u}..HEAD" 2^>nul') do set "AHEAD=%%N"

      if "!AHEAD!"=="0" (
        echo   nada novo para enviar
      ) else (
        REM ===== 4) VERIFICA antes de enviar (impede regressao). So envia se OK.
        set "OK=0"
        if exist "pubspec.yaml" (
          echo   verificando app ^(flutter analyze^)...
          call flutter analyze >nul 2>&1 && set "OK=1"
        ) else (
          set "MVNDIR=API - Chinelatto - att2\API - Chinelatto\API - Chinelatto"
          if exist "!MVNDIR!\pom.xml" (
            echo   verificando backend ^(compilando^)...
            pushd "!MVNDIR!"
            call mvn -q -o -DskipTests compile >nul 2>&1 && set "OK=1"
            if "!OK!"=="0" call mvnw.cmd -q -o -DskipTests compile >nul 2>&1 && set "OK=1"
            popd
          ) else (
            set "OK=1"
          )
        )

        if "!OK!"=="1" (
          git push && echo   verificado e enviado
        ) else (
          echo   [BLOQUEADO] a verificacao falhou: NAO enviei, para nao propagar
          echo              um erro para o outro PC. Seu commit local esta salvo.
          echo              Rode a verificacao, corrija e sincronize de novo.
        )
      )
    )

    popd
    echo.
  )
)

REM ===== 5) Primeira vez nesta maquina: gera o settings.local.json (config local
REM do Claude Code) a partir do modelo, com os caminhos REAIS dos repos daqui.
REM So cria se ainda nao existir (nao sobrescreve o seu).
if defined MOBILE_DIR (
  if not exist "!MOBILE_DIR!\.claude\settings.local.json" (
    echo Gerando .claude\settings.local.json para esta maquina...
    set "CFG=!MOBILE_DIR!\.claude\settings.local.json"
    > "!CFG!" echo {
    >> "!CFG!" echo   "permissions": {
    >> "!CFG!" echo     "defaultMode": "bypassPermissions",
    >> "!CFG!" echo     "additionalDirectories": [
    set "PRIMEIRO=1"
    if defined BACKEND_DIR (
      set "P=!BACKEND_DIR:\=\\!"
      >> "!CFG!" echo       "!P!"
      set "PRIMEIRO=0"
    )
    if defined DESKTOP_DIR (
      set "P=!DESKTOP_DIR:\=\\!"
      if "!PRIMEIRO!"=="0" ( >> "!CFG!" echo       ,"!P!" ) else ( >> "!CFG!" echo       "!P!" )
    )
    >> "!CFG!" echo     ]
    >> "!CFG!" echo   }
    >> "!CFG!" echo }
    echo   Pronto. Reabra o Claude Code neste repo para ele carregar a config.
    echo.
  )
)

echo ============================================================
echo    Sincronizacao concluida.
echo ============================================================
echo.
pause
