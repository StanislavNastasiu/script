@echo off
IF NOT  EXIST "XPaySocketTunnelService.exe" (
   ECHO File XPaySocketTunnelService.exe not found! [Wrong working directory? Working directory is %CD%]
   PAUSE
   exit 1   
)

set validParameter=false
IF [%1]==[/u] set validParameter=true
IF [%1]==[] set validParameter=true

IF "%validParameter%"=="false" (
  
  ECHO Invalid parameter: %1
  ECHO To uninstall, run this script with argument /u
  PAUSE
  exit 2
)                                                                             

IF EXIST "%SYSTEMROOT%\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"  (
   ECHO Using .Net Framework v4.0;
   "%SYSTEMROOT%\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe" %1 "XPaySocketTunnelService.exe" 
) ELSE (
   ECHO Using .Net Framework v2.0.50727;
   "%SYSTEMROOT%\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe" %1 "XPaySocketTunnelService.exe"
)

ECHO To uninstall, run this script with argument /u
ECHO Script completed

