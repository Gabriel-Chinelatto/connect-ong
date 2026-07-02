@echo off
setlocal enabledelayedexpansion
title Sincronizar Connect ONG
chcp 65001 >nul

echo ============================================================
echo    SINCRONIZAR CONNECT ONG  (mobile + backend + desktop)
echo    Puxa do git, envia suas mudancas, em qualquer PC.
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

    REM 1) Traz o remoto guardando as mudancas locais temporariamente
    git pull --rebase --autostash
    if errorlevel 1 (
      echo   [ATENCAO] conflito/erro no pull. Resolva ou peca ajuda no chat.
    ) else (
      REM 2) Envia o que houver de local
      git add -A
      git diff --cached --quiet
      if errorlevel 1 (
        git commit -m "sync automatico" >nul
        git push
        echo   mudancas enviadas
      ) else (
        echo   nada novo para enviar
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
