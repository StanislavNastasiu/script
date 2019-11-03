set _ServiceName=XPaySocketTunnel

sc query %_ServiceName% | find "does not exist" >nul
if %ERRORLEVEL% EQU 0 echo Service Does Not Exist.
if %ERRORLEVEL% EQU 1 net stop %_ServiceName% && net start %_ServiceName%