@echo off

:: check if arg was given
IF "%~1"=="" GOTO no_arg

echo commit message: "DESKTOP: %*"

:: fisch
echo --- STRATEGY GAME ---
:: if index.lock file exists git is being used by another process
:: but this keeps bugging out and i have to del it manually
:: this way might break if legitematelly used by another process 
del /q .git\index.lock
git add .
git commit -m "DESKTOP: %*"
git push origin main

GOTO end

:no_arg
echo need to pass arg for commit message, i.e. %0 added x, removed y 

:end

