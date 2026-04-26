@echo off
setlocal

set "RUNNER=%~dp0run-watch.bat"

start "Codex Remote PC Bridge" /min cmd.exe /d /c ""%RUNNER%""
