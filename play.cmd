@echo off
REM Google Play release helper for this app.
REM
REM NOTE: keep this file ASCII-only. cmd.exe reads batch files using the console
REM code page (949 here, 65001 elsewhere), so non-ASCII comments either show as
REM garbage or break parsing outright. Korean docs live in _automation\README.md.
REM
REM The real logic lives in _automation\fastlane\Fastfile - this is a thin wrapper
REM that only passes the project path, so fixing a lane never means editing 50 copies.
REM
REM   play validate                 verify listing without touching Play
REM   play metadata                 push listing for all locales
REM   play internal                 build + upload to internal testing
REM   play closed                   build + upload to closed testing (alpha)
REM   play beta                     build + upload to open testing
REM   play production               build + upload to production (draft)
REM   play promote to:production    move an existing build between tracks
REM
REM Common options: dry_run:true / status:completed / build_number:N
REM                 aab:<absolute path> / rollout:0.1 / name:<custom closed track>
REM
REM Store listing text is store.cmd, not this script.

setlocal

REM fastlane warns and can mangle non-ASCII output unless the locale is UTF-8.
set "LANG=en_US.UTF-8"
set "LC_ALL=en_US.UTF-8"
set "FASTLANE_SKIP_UPDATE_CHECK=1"
set "FASTLANE_OPT_OUT_USAGE=1"

REM Folder name is the app, its parent is the workspace root. Works on any drive.
for %%I in ("%~dp0.") do set "APP=%%~nxI"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"

REM Absolute path to this project. The shared Fastfile reads it from here.
set "PLAY_APP_DIR=%~dp0"
if "%PLAY_APP_DIR:~-1%"=="\" set "PLAY_APP_DIR=%PLAY_APP_DIR:~0,-1%"

REM Locate _automation. Hardcoding one path breaks when the folder moves or the
REM repo is cloned elsewhere, so look in the nearest places first.
set "AUTO="
if defined PLAY_AUTOMATION if exist "%PLAY_AUTOMATION%\fastlane\Fastfile" set "AUTO=%PLAY_AUTOMATION%"
if not defined AUTO if exist "%ROOT%\_automation\fastlane\Fastfile" set "AUTO=%ROOT%\_automation"
if not defined AUTO if exist "@@AUTOMATION@@\fastlane\Fastfile" set "AUTO=@@AUTOMATION@@"

if not defined AUTO (
  echo [!] Could not find _automation\fastlane\Fastfile. Expected one of:
  echo       %ROOT%\_automation
  echo       @@AUTOMATION@@
  echo.
  echo     Or point PLAY_AUTOMATION at wherever you keep it.
  exit /b 1
)

REM Ruby is not always on the machine PATH. store_listing.ps1 has the same fallback.
if exist "C:\Ruby40-x64\bin\bundle.bat" set "PATH=C:\Ruby40-x64\bin;%PATH%"

cd /d "%AUTO%" || exit /b 1

if "%~1"=="" (
  echo Usage: play ^<lane^> [options]
  echo   app  : %APP%
  echo   dir  : %PLAY_APP_DIR%
  echo   tools: %AUTO%
  echo.
  bundle exec fastlane lanes
  exit /b 1
)

bundle exec fastlane %*
exit /b %ERRORLEVEL%
