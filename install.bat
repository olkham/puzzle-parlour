@echo off
rem Set up Puzzle Parlour's local web server (a small Python virtual environment).
rem Safe to run again: it reuses what is already there.
rem
rem   install.bat                 create or refresh .venv
rem   install.bat --clean         delete .venv and install from scratch
rem   install.bat --python PATH   use this interpreter without asking
rem   install.bat --yes           don't ask; prefer python3
setlocal EnableExtensions
cd /d "%~dp0"

set "VENV=.venv"
set "CLEAN=0"
set "YES=0"
set "PY="

:parse
if "%~1"=="" goto parsed
if /i "%~1"=="--clean" (set "CLEAN=1" & shift & goto parse)
if /i "%~1"=="--yes" (set "YES=1" & shift & goto parse)
if /i "%~1"=="-y" (set "YES=1" & shift & goto parse)
if /i "%~1"=="--help" goto usage
if /i "%~1"=="-h" goto usage
if /i "%~1"=="--python" (
  if "%~2"=="" (echo --python needs a path & exit /b 2)
  set "PY=%~2"
  shift
  shift
  goto parse
)
echo Unknown option: %~1
call :usage
exit /b 2
:parsed

if "%CLEAN%"=="1" if exist "%VENV%" (
  echo Removing %VENV% for a fresh install...
  rmdir /s /q "%VENV%"
)

if exist "%VENV%\Scripts\python.exe" (
  "%VENV%\Scripts\python.exe" -c "import sys" >nul 2>nul && goto reuse
  echo %VENV% looks broken; recreating it.
  rmdir /s /q "%VENV%"
)

if not "%PY%"=="" (
  call :check "%PY%" || (echo "%PY%" isn't Python 3.8 or newer. & exit /b 1)
  goto havepy
)

rem check for both python and python3, and let you pick which one builds the .venv
set "HAVE1=0"
set "HAVE2=0"
call :check python && set "HAVE1=1"
call :check python3 && set "HAVE2=1"
if "%HAVE1%%HAVE2%"=="10" (set "PY=python" & goto havepy)
if "%HAVE1%%HAVE2%"=="01" (set "PY=python3" & goto havepy)
if "%HAVE1%%HAVE2%"=="00" goto nopython

echo Found two Pythons:
for /f "delims=" %%v in ('python --version 2^>^&1') do echo   1^) python    %%v
for /f "delims=" %%v in ('python3 --version 2^>^&1') do echo   2^) python3   %%v
set "CHOICE=2"
if "%YES%"=="0" set /p "CHOICE=Which one should create the .venv? [1/2, Enter = 2]: "
if "%CHOICE%"=="1" (set "PY=python") else (set "PY=python3")

:havepy
echo Creating %VENV% with %PY%...
"%PY%" -m venv "%VENV%"
if errorlevel 1 (
  echo Couldn't create the virtual environment.
  exit /b 1
)
goto deps

:reuse
echo Using existing %VENV%.

:deps
echo Installing the optional QR-code helper...
"%VENV%\Scripts\python.exe" -m pip install --disable-pip-version-check -q -r requirements.txt
if errorlevel 1 (
  echo Couldn't install qrcode ^(offline?^). The games still work; you just won't get a QR code.
) else (
  echo Done.
)
echo.
echo All set. Start the games with:  run.bat
echo ^(or just open index.html in a browser^)
endlocal
exit /b 0

:nopython
rem last resort: the Windows "py" launcher
call :check py && (set "PY=py" & goto havepy)
echo Python 3.8+ was not found as python or python3.
echo Install it from https://www.python.org/downloads/ ^(tick "Add python.exe to PATH"^), then run this again.
exit /b 1

:check
where %1 >nul 2>nul || exit /b 1
%1 -c "import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>nul || exit /b 1
exit /b 0

:usage
echo Usage: install.bat [--clean] [--python PATH] [--yes]
echo   --clean        delete .venv and install from scratch
echo   --python PATH  use this interpreter without asking
echo   --yes          don't ask; prefer python3
exit /b 0
