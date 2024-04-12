#!/usr/bin/env sh
set -e
# Wait. Why not just use $PWD?
CURDIR=$(pwd)
WINE=${WINE-wine}
WINE64="${WINE}64"

if [ -z "$WINEPREFIX" ];then
	export WINEPREFIX=$HOME/.wine
fi

echo Installing to $WINEPREFIX
PWSH_64_PATH=$($WINE64 winepath -u 'C:\windows\system32\WindowsPowerShell/v1.0/powershell.exe' 2> /dev/null)
PWSH_32_PATH=$($WINE winepath -u 'C:\windows\system32\WindowsPowerShell/v1.0/powershell.exe' 2> /dev/null)

cp -v "$CURDIR/x86/powershell.exe" "$PWSH_32_PATH"
cp -v "$CURDIR/x86_64/powershell.exe" "$PWSH_64_PATH"
$WINE reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v powershell.exe /d native /f
