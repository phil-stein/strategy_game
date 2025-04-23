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
  :: odin run src -out:bin\game.exe -vet-shadowing -vet-using-stmt -define:EDITOR=true
  odin run src -out:bin\game.exe  -vet-cast -vet-shadowing -vet-using-stmt -vet-using-param -define:EDITOR=true
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
:: -sanitize:<string>
::         Enables sanitization analysis.
::         Available options:
::                 -sanitize:address
::                 -sanitize:memory
::                 -sanitize:thread
::         NOTE: This flag can be used multiple times.
:: -o:<string>
::         Sets the optimization mode for compilation.
::         Available options:
::                 -o:none
::                 -o:minimal
::                 -o:size
::                 -o:speed
::                 -o:aggressive (use this with caution)
::         The default is -o:minimal.
:: -vet
::         Does extra checks on the code.
::         Extra checks include:
::                 -vet-unused
::                 -vet-unused-variables
::                 -vet-unused-imports
::                 -vet-shadowing
::                 -vet-using-stmt
::
:: -vet-cast
::         Errs on casting a value to its own type or using `transmute` rather than `cast`.
::
:: -vet-packages:<comma-separated-strings>
::         Sets which packages by name will be vetted.
::         Files with specific +vet tags will not be ignored if they are not in the packages set.
::
:: -vet-semicolon
::         Errs on unneeded semicolons.
::
:: -vet-shadowing
::         Checks for variable shadowing within procedures.
::
:: -vet-style
::         Errs on missing trailing commas followed by a newline.
::         Errs on deprecated syntax.
::         Does not err on unneeded tokens (unlike -strict-style).
::
:: -vet-tabs
::         Errs when the use of tabs has not been used for indentation.
::
:: -vet-unused
::         Checks for unused declarations (variables and imports).
::
:: -vet-unused-imports
::         Checks for unused import declarations.
::
:: -vet-unused-procedures
::         Checks for unused procedures.
::         Must be used with -vet-packages or specified on a per file with +vet tags.
::
:: -vet-unused-variables
::         Checks for unused variable declarations.
::
:: -vet-using-param
::         Checks for the use of 'using' on procedure parameters.
::         'using' is considered bad practice outside of immediate refactoring.
::
:: -vet-using-stmt
::         Checks for the use of 'using' as a statement.
::         'using' is considered bad practice outside of immediate refactoring.


:: -vet-unused
:: -vet-unused-variables
:: -vet-unused-imports
:: -sanitize:address
odin run src -out:bin\game.exe  -vet-cast -vet-shadowing -vet-using-stmt -vet-using-param -debug  -define:EDITOR=true

:eof
