echo off
powershell -Command "& {Unblock-File .\ExtractPressureData.ps1}"
%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe .\ExtractPressureData.ps1
pause