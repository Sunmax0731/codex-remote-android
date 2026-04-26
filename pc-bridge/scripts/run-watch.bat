@echo off
setlocal

set "BRIDGE_DIR=%~dp0.."
set "LOG_DIR=%BRIDGE_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\pc-bridge-watch-%RANDOM%.log"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

pushd "%BRIDGE_DIR%" || exit /b 1

echo [%date% %time%] Starting Codex Remote PC bridge watcher.>> "%LOG_FILE%"
echo Log file: %LOG_FILE%
call npm.cmd run start:watch >> "%LOG_FILE%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"
echo [%date% %time%] Codex Remote PC bridge watcher exited with code %EXIT_CODE%.>> "%LOG_FILE%"

popd
exit /b %EXIT_CODE%
