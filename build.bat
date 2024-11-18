@echo off

del bin\game.exe

:: only on linux: -sanitize:memory -sanitize:thread
:: -sanitize:address
:: -vet-unused -vet-unused-variables -vet-unused-imports
odin run src -out:bin\game.exe  -vet-shadowing -vet-using-stmt -debug
