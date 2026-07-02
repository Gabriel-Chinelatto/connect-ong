@echo off
setlocal enabledelayedexpansion
title Sincronizar Connect ONG
chcp 65001 >nul

echo ============================================================
echo    SINCRONIZAR CONNECT ONG  (mobile + backend + desktop)
echo    Puxa do git, envia suas mudancas, em qualquer PC.
echo ============================================================
echo.

REM Descobre os 3 repos testando caminhos candidatos sob o SEU usuario
REM (cobre este PC e o notebook, com layouts diferentes). So sincroniza
REM os que existirem e forem repositorio git.

call :sync "%USERPROFILE%\connect-ong"
call :sync "%USERPROFILE%\Desktop\connect-ong"
call :sync "%USERPROFILE%\IdeaProjects\connect-ong-api"
call :sync "%USERPROFILE%\Desktop\connect-ong-api"
call :sync "%USERPROFILE%\connect_ong - Desktop"
call :sync "%USERPROFILE%\Desktop\connect_ong - Desktop"
call :sync "%USERPROFILE%\Desktop\connect-ong-desktop"

echo.
echo ============================================================
echo    Sincronizacao concluida.
echo ============================================================
echo.
pause
exit /b

:sync
REM %~1 = pasta candidata. Ignora se nao existir ou nao for repo git.
if not exist "%~1\.git" exit /b
echo --- %~1
pushd "%~1"

REM 1) Traz mudancas do remoto (guardando as locais temporariamente)
git pull --rebase --autostash
if errorlevel 1 (
    echo   [ATENCAO] conflito/erro no pull aqui. Resolva ou peca ajuda no chat.
    popd
    echo.
    exit /b
)

REM 2) Envia suas mudancas locais, se houver
git add -A
git diff --cached --quiet && (
    echo   nada novo para enviar
) || (
    git commit -m "sync automatico" >nul
    git push
    echo   mudancas enviadas
)

popd
echo.
exit /b
