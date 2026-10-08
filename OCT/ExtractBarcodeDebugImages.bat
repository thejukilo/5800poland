echo off
powershell -Command "& {Unblock-File .\ExtractBarcodeDebugImages.ps1}"
%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe .\ExtractBarcodeDebugImages.ps1
pause