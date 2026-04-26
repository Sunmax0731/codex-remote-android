@echo off
setlocal

set "TASK_NAME=CodexRemotePcBridge"
set "RUNNER=%~dp0run-watch.bat"
set "TASK_COMMAND=cmd.exe /d /c ""%RUNNER%"""

schtasks /Create /TN "%TASK_NAME%" /TR "%TASK_COMMAND%" /SC ONLOGON /F
if errorlevel 1 exit /b %ERRORLEVEL%

echo Registered task: %TASK_NAME%
echo Start now with:
echo schtasks /Run /TN "%TASK_NAME%"
