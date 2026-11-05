@echo off
rem Serve Puzzle Parlour at http://localhost:8080 (and on your Wi-Fi, for your phone).
rem   run.bat                   start on port 8080 and open a browser tab
rem   run.bat --port 9000       use another port
rem   run.bat --no-browser      don't open a tab
rem   run.bat --host 127.0.0.1  only this computer can connect
setlocal
cd /d "%~dp0"
if not exist ".venv\Scripts\python.exe" (
  echo No .venv yet. Run install.bat first ^(or just open index.html in a browser^).
  exit /b 1
)
".venv\Scripts\python.exe" serve.py %*
