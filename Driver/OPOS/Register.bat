
@echo on

Pushd C:\Program Files\DieboldNixdorf\OposDriver\OPOSCCO-1.14.1
RegComSvr.exe %1 CommonCO\OPOS*.ocx CommonCO\Opos*.dll
