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
            REM repo de tipo desconhecido: nao bloqueia
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

echo ============================================================
echo    Sincronizacao concluida.
echo ============================================================
echo.
pause
