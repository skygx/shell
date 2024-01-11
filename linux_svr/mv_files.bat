@echo off
setlocal enabledelayedexpansion
for /r %%i in (*) do (
  if not "%%~pi"=="%cd%\" (
    move "%%i" "%cd%\"
  )
)
for /d %%i in (*) do (
  if not "%%i"=="%~nx0" (
    rd "%%i" /s /q
  )
)