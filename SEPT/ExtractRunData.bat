echo off
powershell -Command "& {Unblock-File .\ExtractRunData.ps1}"
%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe .\ExtractRunData.ps1
pause