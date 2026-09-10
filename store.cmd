@echo off
REM Google Play store listing helper for this app.
REM
REM NOTE: keep this file ASCII-only. cmd.exe reads batch files using the console
REM code page (949 here, 65001 elsewhere), so non-ASCII comments either show as
REM garbage or break parsing outright. Korean docs live in _automation\README.md.
REM
REM The real logic lives in _automation\store_listing.ps1 - this is a thin wrapper
REM that only passes the app name and workspace root, so fixing behaviour never
REM means editing 50 copies.
REM
REM   store status           show Play release / local locales / source doc
REM   store from-docs        docs/store/google-store.md -> fastlane metadata
REM   store from-docs -Force overwrite existing metadata from the doc
REM   store pull             Play Console -> metadata (text only, no images)
REM   store push -DryRun     validate without writing to Play
REM   store push             apply to Play Console
REM
REM Building and uploading AABs is _automation\release_all.ps1, not this script.

setlocal
REM Folder name is the app, its parent is the workspace root. Works on any drive.
for %%I in ("%~dp0.") do set "APP=%%~nxI"
for %%I in ("%~dp0..") do set "ROOT=%%~fI"

REM Locate _automation. Hardcoding one path breaks when the folder moves or the
REM repo is cloned elsewhere, so look in the nearest places first.
set "AUTO="
if defined STORE_AUTOMATION if exist "%STORE_AUTOMATION%\store_listing.ps1" set "AUTO=%STORE_AUTOMATION%"
if not defined AUTO if exist "%ROOT%\_automation\store_listing.ps1" set "AUTO=%ROOT%\_automation"
if not defined AUTO if exist "@@AUTOMATION@@\store_listing.ps1" set "AUTO=@@AUTOMATION@@"

if not defined AUTO (
  echo [!] Could not find _automation. Expected one of:
  echo       %ROOT%\_automation
  echo       @@AUTOMATION@@
  echo.
  echo     Clone it if missing:
  echo       git clone https://github.com/dangundad/_automation
  echo.
  echo     Or point STORE_AUTOMATION at wherever you keep it.
  exit /b 1
)

if "%~1"=="" (
  echo Usage: store ^<status^|from-docs^|pull^|push^> [options]
  echo   app  : %APP%
  echo   root : %ROOT%
  echo   tools: %AUTO%
  exit /b 1
)

pwsh -NoProfile -File "%AUTO%\store_listing.ps1" %1 -Apps "%APP%" -Root "%ROOT%" %2 %3 %4 %5 %6
exit /b %ERRORLEVEL%
