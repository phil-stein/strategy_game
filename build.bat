@echo off

del deferred.exe

:: only on linux: -sanitize:memory -sanitize:thread
:: -sanitize:address
:: -vet-unused -vet-unused-variables -vet-unused-imports
odin run src -out:deferred.exe  -vet-shadowing -vet-using-stmt  -debug
