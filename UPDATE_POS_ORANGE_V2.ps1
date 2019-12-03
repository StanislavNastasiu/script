#region FUNZIONI DI UTILITA'
param([switch]$Elevated)

function Test-Admin 
{
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  
{
    if ($elevated) 
    {
        # tried to elevate, did not work, aborting
    } 
    else 
    {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }

    exit
}
'running with full privileges'
#endregion
function Test-Admin 
{
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

#region SCRIPT
$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'
$Host.PrivateData.ErrorForegroundColor = 'DarkRed'
$Host.PrivateData.ErrorBackgroundColor = 'Black'
$Host.PrivateData.WarningForegroundColor = 'Yellow'
$Host.PrivateData.WarningBackgroundColor = 'Black'
$Host.PrivateData.DebugForegroundColor = 'Yellow'
$Host.PrivateData.DebugBackgroundColor = 'Black'
$Host.PrivateData.VerboseForegroundColor = 'Green'
$Host.PrivateData.VerboseBackgroundColor = 'Black'
$Host.PrivateData.ProgressForegroundColor = 'DarkGray'
$Host.PrivateData.ProgressBackgroundColor = 'Black'
Set-Location ~/
Clear-Host

$Global:pos_username = $null
$Global:pos_password = $null
$Global:sqlserver = $null
$Global:sqlinstance = $null
$Global:sqluser = $null
$Global:sqlpassword = $null
$Global:ProgressPreference = 'SilentlyContinue'
$Global:LoggerLevel = $null
$Global:StoreType = $null
$Global:CorporateCodePrefix = $null
$Global:ChainCode = $null
$Global:WincorBCIP = $null
$Global:RTMODE = $null

#directory di esecuzione dello script
$currentDir = split-path -parent $MyInvocation.MyCommand.Definition
function loadSettings{

    $configPath = $currentDir+"\config.xml"
    if(-not(Test-Path($configPath))){
        Write-Host "File di configurazione non trovato"
        Pause
        Exit
    }
    [xml]$ConfigFile = Get-Content $configPath
    $Global:pos_username = $ConfigFile.settings.credentials.user
    $Global:pos_password = $ConfigFile.settings.credentials.password | ConvertTo-SecureString -AsPlainText -Force
    $Global:sqlserver = $ConfigFile.settings.SQLServer.instance
    $Global:sqluser = $ConfigFile.settings.SQLServer.user
    $Global:sqlpassword = $ConfigFile.settings.SQLServer.password
    $Global:LoggerLevel  = $ConfigFile.settings.Logger.level
    $Global:StoreType = $ConfigFile.settings.store
    $Global:WincorBCIP = $ConfigFile.settings.BuonoChiaro.IpAddress
    $Global:RTMODE = $ConfigFile.settings.RTONE.Mode
}
loadSettings

switch ($Global:StoreType) {
    "MARTINELLI" { 
        $Global:CorporateCodePrefix = "048700"
        $Global:ChainCode = "01"
    }
    "VISOTTO" { 
        $Global:CorporateCodePrefix = "046400"
        $Global:ChainCode = "06"
    }
    Default {
        Write-Host "Il negozio selezionato non è compatibile con lo script" -ForegroundColor White -BackgroundColor Red
        Pause
        break
        Exit
    }
}
Clear-Host
Write-Host "PROCEDURA DI AGGIORNAMENTO ORANGE V5" -ForegroundColor White -BackgroundColor DarkCyan
Write-Host "V. $Global:StoreType" -BackgroundColor Yellow -ForegroundColor Black

Write-Output ""
Write-Output ""
$currStep=1
#region PASSO 1 - CREAZIONE PARAMETRI

    Write-Output "Creazione parametri..."
    Write-Output ""
    #
    #generazione di tutti i parametri necessari all'esecuzione dello script
    #
    #carattere per tabulazione
    $TAB_CHR = [char]9
    
    $arr = @()
    while($val = Read-Host "Inserire codice cassa da aggiornare [per terminare premere invio] ") {
        if ($val -eq "" -or $val -eq $null) {break}
        $arr += "'"+$val+"',"
    }
    $len=$arr.Length
    $arr.Set($len-1,$arr[$len-1].Replace(",",""))
    [string]$array_POS=$arr 

    #Import file funzioni
    Import-Module $currentDir\funzioni.ps1
    #data di oggi
    $today = Get-Date -Format "yyyyMMdd"
    #Codice negozio
    $StoreCode_raw = getStoreCode
    Write-Host ""
    $StoreCod = $StoreCode_raw[0]
    #header negozio
    $raw_header= Get-Content -Path "$currentDir\Orange\ClientPOS_RT\Template\Header.vm" | Where-Object {$_ -match "<text>"}
    $header= $raw_header.Replace("<text><![CDATA[","`n").Replace("]]></text>","`n").Replace("<text>","`n").Replace("</text>","`n")
    Write-Host ""
    Write-Host "CODICE NEGOZIO = $StoreCod" -ForegroundColor White -BackgroundColor DarkRed
    Write-Host ""
    Write-Host "CASSE SELEZIONATE: $array_POS" -ForegroundColor White -BackgroundColor DarkRed
    Write-Output ""
    Write-Host "Controllare Header sottostante prima di procedere" -ForegroundColor Yellow
    Write-Host "══════════════════════════════════════════════════════════"
    Write-Host $header
    Write-Host "══════════════════════════════════════════════════════════"
    Write-Output ""
    Write-Host "FINITO" -ForegroundColor Black -BackgroundColor Green

#endregion

# verifica che l'unica J non sia gia' mappata, se lo e' la elimino
if(Test-Path -LiteralPath  "J:")
{
    try{
        Get-PSDrive J | Remove-PSDrive
    }
    catch{
        Clear-Host
        Write-Host "Disco di rete J: presente, disconnettersi manualmente" -ForegroundColor Red

        Pause
        break
        Clear-Host
    }
}
Pause
Clear-Host
menu




