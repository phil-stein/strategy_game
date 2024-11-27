@echo off

del bin\game.exe

:: check if no arg was given
IF "%~1"=="" GOTO debug 

IF "%~1"=="debug" ( 
  GOTO debug 
)

IF "%~1"=="game" ( 
  echo --- building game ---
  :: -o:speed
  odin run src -out:bin\game.exe -vet-shadowing -vet-using-stmt -define:EDITOR=false 
  GOTO eof 
)

IF "%~1"=="nodebug" ( 
  echo --- building no-debug ---
  :: -o:speed
  odin run src -out:bin\game.exe -vet-shadowing -vet-using-stmt -define:EDITOR=true
  GOTO eof 
)

echo incorrect argument: "%~1"
echo   build or build debug
echo   build game
echo   build nodebug
GOTO eof

:debug
echo --- building debug ---
:: only on linux: -sanitize:memory -sanitize:thread
:: -sanitize:address
:: -vet-unused -vet-unused-variables -vet-unused-imports
odin run src -out:bin\game.exe  -vet-shadowing -vet-using-stmt -debug -define:EDITOR=true

:eof
