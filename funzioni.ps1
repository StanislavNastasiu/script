function Write-Log
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory=$false)] 
        [Alias('LogPath')] 
        [string]$Path=$currentDir+"\"+"$today"+"_script.log", 
         
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Info")] 
        [string]$Level="Info", 
         
        [Parameter(Mandatory=$false)] 
        [switch]$NoClobber 
    ) 
 
    Begin 
    { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = $Global:LoggerLevel
    } 
    Process 
    { 
         
        # If the file already exists and NoClobber was specified, do not write to the log. 
        if ((Test-Path $Path) -AND $NoClobber) { 
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
            Return 
            } 
 
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        elseif (!(Test-Path $Path)) { 
            Write-Verbose "Creating $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
            } 
 
        else { 
            # Nothing to see here yet. 
            } 
 
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level) { 
            'Error' { 
                Write-Warning $Message 
                $LevelText = '| ERROR |' 
                } 
            'Warn' { 
                Write-Warning $Message 
                $LevelText = '| WARNING |' 
                } 
            'Info' { 
                Write-Verbose $Message 
                $LevelText = '| INFO |' 
                } 
            } 
         
        # Write log entry to $Path 
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append 
    } 
    End 
    { 
    } 
}
#verifica se il servizio windows esiste ed è avviato, in caso positivo lo stoppa
function ServiceStopper ([string]$serviceName)
{
    If ((Get-Service $serviceName -ErrorAction SilentlyContinue) -and ((Get-Service $serviceName).Status -eq 'Running') )
    {
        Stop-Service $serviceName
        Write-Host "Stopping $serviceName"
        Write-Log -Level Info "Stopping $serviceName"
    } 
}
function ServiceStarter ([string]$serviceName)
{
    If ((Get-Service $serviceName -ErrorAction SilentlyContinue) -and ((Get-Service $serviceName).Status -ne 'Running') )
    {
        Start-Service $serviceName
        Write-Host "Starting $serviceName"
        Write-Log -Level Info "Starting $serviceName"
    } 
}
<# Funzione che controlla ed installa java
function getJAVAV(){
    $jv = Get-Command java | Select-Object Version

    $JavaVer = $jv.Version.ToString()

    $jvPath = Get-Command java | Select-Object Path

    $JavaPath=$jvPath.Path.ToString()

    Write-Host "Java version attuale: $JavaVer"
    Write-Host "Java path attuale: $JavaPath"

    Pause
    Clear-Host

    if(([string]::IsNullOrEmpty($JavaVer))-or $JavaVer -ne "8.0.2210.11"){

        Write-Host "Versione java installata: $Javaver" -ForegroundColor Yellow
        Write-Host "Attendi installazione/aggiornamento java..." -ForegroundColor cyan
        Start-Process .\util\jrex64.exe /s -Wait 
    }

    Sleep -Seconds 2

    $jv = Get-Command java | Select-Object Version

    $JavaVer = $jv.Version.ToString()

    $jvPath = Get-Command java | Select-Object Path

    $JavaPath=$jvPath.Path.ToString()

    Write-Host "Java version: $JavaVer"
    Write-Host "Java path: $JavaPath"

    Pause
    Clear-Host


    if($JavaVer -eq "8.0.2210.11"){
        Write-Host "Aggiornamento terminato con successo" -ForegroundColor Green
    }
}
 #>
#verifica se il valore contenuto in una variabile è numerico
function IsNumeric ([string]$value)
{
    return ([string]($value -as [int]))
}
function TestPath([string] $path){

    if(-not(Test-Path -LiteralPath $path)){
        return $false
    }
    else {
        return $true
    }
}
function TestConnection([string] $target){
    if(-not(Test-NetConnection -RemoteAddress $target -InformationLevel Quiet)){
        return $false
    }
    else{
        return $true
    }
}
function backup($source,$dest){

    #region BACKUP
    Write-Output ""
    Write-Output ("Backup cartella: "+$source+"....")
    Write-Log -Level Info ("Backup cartella "+"$source")
    #Copying folder

    if(-not(TestPath($source))){
        Write-Host "Percorso non trovato" -BackgroundColor Red -ForegroundColor White
        Write-Log -Level Error ("Percorso non trovato "+$source)
        break
    }
    
    try{

       robocopy $source $dest /e /NFL /NDL /NJH /NJS /nc /ns /np /MT:32
       Write-Output ""
       Write-Output "Backup completato"
       Write-Log -Level Info "Backup completato"
    }
    catch{
        Clear-Host
        Write-Host "Impossibile fare il backup..." -ForegroundColor Red
        Write-Log -Level Error "Impossibile fare il backup"
        Pause
        break
        Clear-Host
    }
    finally{
        Write-Host "FINITO" -ForegroundColor Black -BackgroundColor Green
    }
    #endregion
}
function update($source,$dest){

    #region CASSE UPDATE
    #esegue le operazioni di aggiornamento cassa
    Write-Host ("Aggiornamento cartella: "+$dest+" ...")  -ForegroundColor White -BackgroundColor Blue
    Write-Log -Level Info ("Aggiornamento cartella: "+"$dest")
    Write-Output ""

    if(-not(TestPath($source) -or TestPath($dest))){
        Write-Host "Percorso non trovato" -BackgroundColor Red -ForegroundColor White
        Write-Log -Level Error ("Percorso non trovato"+"$dest"+" | "+"$source")
        break
    }

    try{
        robocopy $source $dest /e /NFL /NDL /NJH /NJS /nc /ns /np /MT:32
    }
    catch{
        Clear-Host
        Write-Host ("Impossibile aggiornare "+$dest+" ...") -ForegroundColor Red
        Write-Log -Level Error ("Impossibile aggiornare: "+"$dest")
        Pause
        break
        Clear-Host
    }
    finally{
     
        Write-Host "Trasferimento file terminato"  -ForegroundColor White -BackgroundColor Blue
        Write-Log -Level Info "Trasferimento file terminato"
    }
    #endregion
}
function getPOS([string]$array_POS){

    Write-Host "Recupero dati dal database di OrangeServer" -ForegroundColor Yellow
    Write-Log -Level Info "Recupero dati dal database di OrangeServer"
    try{
        if($array_POS.Contains("*")){
            $DataRows = Invoke-Sqlcmd -ServerInstance $Global:sqlserver -Database 'OrangeServer' -Query "SELECT ipaddress,description,code FROM client WHERE code <> '999'"
        }
        else{
            $DataRows = Invoke-Sqlcmd -ServerInstance $Global:sqlserver -Database 'OrangeServer' -Query "SELECT ipaddress,description,code FROM client WHERE code in($array_POS)"
        }
        Write-Host "Dati recuperati con successo" -ForegroundColor Green
        Write-Log -Level Info "Dati recuperati con successo"
        return $DataRows
    }
    catch{
        Clear-Host
        Write-Host "Server orange non raggiungibile, controllare i parametri" -ForegroundColor Red
        Write-Log -Level Error "Server orange non raggiungibile, controllare i parametri"
        Pause
        break
        Clear-Host
    }
    finally{
        Push-Location -Path $currentDir
    }
}
function getStoreCode(){

    Write-Host "Recupero dati dal database di OrangeServer" -ForegroundColor Yellow
    Write-Log -Level Info "Recupero dati dal database di OrangeServer"
    try{
        $StoreCode = Invoke-Sqlcmd -ServerInstance $Global:sqlserver -Database 'OrangeServer' -Query "SELECT Code FROM Store"
        Write-Host "Dati recuperati con successo" -ForegroundColor Green
        Write-Log -Level Info "Dati recuperati con successo"
        return $StoreCode
    }
    catch{
        Clear-Host
        Write-Host "Server orange non raggiungibile, controllare i parametri" -ForegroundColor Red
        Write-Log -Level Error "Server orange non raggiungibile, controllare i parametri"

        Pause
        break
        Clear-Host
    }
    finally{
        Push-Location -Path $currentDir
    }
}
function restore([string]$ipPOS){
    
    #region RESTORE BACKUP
    Write-Output ""
    Write-Output ("Ripristino backup della cassa: $ipPOS")
    $ipPOSX="\\$ipPOS"+"\c$"
    $dest="X:\Orange\ClientPOS"
    #Copying folder
    try{
        New-PSDrive -name X -Root $ipPOSX -Credential $Cred -PSProvider filesystem -Persist
        Get-ChildItem -Directory -Path "X:\Orange" -Name -Filter "bck_*"
        Write-Host ""
        #data bck
        $date = Read-Host 'Inserire la data del bck'
        $source="X:\Orange\bck_ClientPOS_"+$date
    }
    catch{
        Clear-Host
        Write-Host "Impossibile ripristinare il backup..." -ForegroundColor Red

        Pause
        break
        Clear-Host
    }
    finally{
        Write-Host "Ripristino in corso..."
        robocopy $source $dest /e /NFL /NDL /NJH /NJS /nc /ns /np /MT:32
        Get-PSDrive X | Remove-PSDrive
        Write-Output ""
        Write-Output "Ripristino completato"
        Write-Host "FINITO" -ForegroundColor Black -BackgroundColor Green
    }
    #endregion
}
function menu(){

    Clear-Host
    # richiesta inserimento opzione
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╔══════════════════════════════╗"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║1)Trasferisci ClientPos_RT    ║"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║Q)Exit                        ║" -ForegroundColor White -BackgroundColor DarkRed
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╚══════════════════════════════╝"

    $tipoOperazione = Read-Host 'Inserire la funzione da eseguire'
    Clear-Host

    #Recupero informazioni DB OrangeServer
    $totalPOS = 0
    $RecordPOS=getPOS($array_POS)
    foreach($client in $RecordPOS){
        $totalPOS++
        Write-Log -Level Info ("Casse selezionate: "+$client.description)
    }

    #verifica che la tipologia di cassa sia un valore INTERO
    if(IsNumeric($tipoOperazione))
    {
        #crea credenziali di accesso alla cartella remota
        $Cred = New-Object System.Management.Automation.PsCredential($Global:pos_username,$Global:pos_password)
        

        switch ($tipoOperazione)
        {
            1
            {
                Write-Log -Level Info "Inizio operazione 1 - UPDATE ClientPOS"
                Write-Host "Numero casse da aggiornare: $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                Pause
                Clear-Host
                $currPos=1
                foreach ($ip in $RecordPOS) 
                {
                    Write-Host "Aggiornamento cassa $currPos di $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                    Write-Log -Level Info ("Aggiornamento cassa $currPos di $totalPOS")
                    Write-Log -Level Info ("CASSA: "+$ip.ipaddress)
                    #path remoto alla cassa
                    $uncPathPOS = "\\" + $ip.ipaddress + "\c$"
                    #path remoto alla cartella Orange
                    $uncPathOrange = "J:\Orange"
                    $uncPathClientPos ="$uncPathOrange\ClientPOS_RT"

                    if(-not(TestConnection($ip.ipaddress))){
                        Clear-Host
                        Write-Host "Cassa non ragiungibile, verrà saltata" -ForegroundColor White -BackgroundColor Red
                        Write-Log -Level Error ("Cassa "+$ip.ipaddress+" non ragiungibile, verrà saltata")
                        Pause
                        Clear-Host
                        continue
                    }

                    try{

                        New-PSDrive -name J -Root $uncPathPOS -Credential $cred -PSProvider filesystem -Persist
                        Write-Host ("Creato collegamento con la cassa: "+$ip.description) -ForegroundColor Black -BackgroundColor Green
                        Write-Log -Level Info ("Creato collegamento con la cassa: "+$ip.description)
                    }
                    catch{
                        Clear-Host
                        Write-Host "Impossibile creare il disco di rete J, controllare i parametri e che il disco non sia gia' presente (scollegarlo nel caso)" -ForegroundColor Red
                        Write-Log -Level Error "Impossibile creare il disco di rete J, controllare i parametri e che il disco non sia gia' presente (scollegarlo nel caso)"
                        Pause
                        break
                        Clear-Host
                    }
                    Pause
                    #UPDATE ClientPOS

                    #esegue le operazioni di aggiornamento cassa
                    $sourceClientPOS= "$currentDir\Orange"
                    update $sourceClientPOS $uncPathOrange
                    Pause
                    Clear-Host

                    #MODIFICA CLIENTCONFIGURATION
                    Write-Host "Aggiornamento clientConfiguration.config"  -ForegroundColor White -BackgroundColor Blue
                    Write-Log -Level Info "Aggiornamento clientConfiguration.config"
                    Write-Output ""
                    try{
                        #percorso completo al file clientConfiguration
                        $xml = [xml](Get-Content $uncPathClientPos"\clientConfiguration.config")

                        $Dictionary = @{
                            ChainCode = $Global:ChainCode
                            WorkstationCode    = $ip.code
                            WorkstationName     = 'Client '+$ip.code
                            StoreCode = $StoreCod
                            ServerAddress = ( Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $env:COMPUTERNAME | Where-Object { $_.IPaddress -ne $null } ).IPAddress[0]
                        }

                        foreach($key in $Dictionary.Keys)
                        {
                            if(($addKey = $xml.SelectSingleNode("//clientConfiguration/add[@key = '$key']")))
                            {
                                Write-Host "'$key'= $($Dictionary[$key])" -ForegroundColor Yellow
                                $addKey.SetAttribute('value',$Dictionary[$key])
                            }
                        }
                    }
                    catch{
                        Clear-Host
                        Write-Host "Impossibile modificare il file clientConfiguration..." -ForegroundColor Red
                        Write-Log -Level Error "Impossibile modificare il file clientConfiguration..."
                        Pause
                        break
                        Clear-Host     
                    }
                    finally{
                    
                        $xml.Save($uncPathClientPos+"\clientConfiguration.config")
                        Write-Log -Level Info "File clientConfiguration.config salvato"
                        Write-Host "File clientConfiguration.config salvato..." -ForegroundColor Green
                        Write-Host "$TAB_CHR FINITO" -ForegroundColor Black -BackgroundColor Green                  
                    }
                    Pause

                    #MODIFICA ENGINE
                    Write-Host "Aggiornamento engine.config"  -ForegroundColor White -BackgroundColor Blue
                    Write-Log -Level Info "Aggiornamento engine.config"
                    Write-Output ""
                    try{
                        #percorso completo al file engine
                        $engine = [xml](Get-Content $uncPathClientPos"\engine.config")
                        $CorpCode=$Global:CorporateCodePrefix+$StoreCod
                        $TillNum=$StoreCod+$ip.code
                        $IpAdress = $Global:WincorBCIP
                        $LocalIP = ( Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $env:COMPUTERNAME | Where-Object { $_.IPaddress -ne $null } ).IPAddress[0]

                        $ns = New-Object System.Xml.XmlNamespaceManager($engine.NameTable)
                        $ns.AddNamespace("ns", $engine.DocumentElement.NamespaceURI)
                        $object = $engine.SelectSingleNode("//ns:object[@name='TM.BuonoChiaro']", $ns)
                        foreach($name in $object.property){
                                if($name.name -eq "CorporateCode"){
                                    $name.SetAttribute('value',$CorpCode)
                                    Write-Host "Aggiornato CorporateCode: "$CorpCode -ForegroundColor Yellow
                                    Write-Log -Level Info ("Aggiornato CorporateCode: "+$CorpCode)
                                }
                                if($name.name -eq "TillNumber"){
                                    $name.SetAttribute('value',$TillNum)
                                    Write-Host "Aggiornato TillNumber: "$TillNum -ForegroundColor Yellow
                                    Write-Log -Level Info ("Aggiornato TillNumber: "+$TillNum)
                                }
                                if($name.name -eq "LocalIpAddress"){
                                    $name.SetAttribute('value',$LocalIP)
                                    Write-Host "Aggiornato LocalIpAddress: "$LocalIP -ForegroundColor Yellow
                                    Write-Log -Level Info ("Aggiornato LocalIpAddress: "+$LocalIP)
                                }
                                if($name.name -eq "IpAddress"){
                                    $name.SetAttribute('value',$IpAdress)
                                    Write-Host "Aggiornato IpAddress: "$IpAdress -ForegroundColor Yellow
                                    Write-Log -Level Info ("Aggiornato IpAddress: "+$IpAdress)
                                }
                        }
                    }
                    catch{
                        Clear-Host
                        Write-Host "Impossibile modificare il file engine..." -ForegroundColor Red
                        Write-Log -Level Error "Impossibile modificare il file engine"
                        Pause
                        break
                        Clear-Host
                    }
                    finally{
                    
                        $engine.Save($uncPathClientPos+"\engine.config")
                        Write-Host "File engine.config salvato..." -ForegroundColor Green
                        Write-Log -Level Info "File engine.config salvato"
                        Write-Host "$TAB_CHR FINITO" -ForegroundColor Black -BackgroundColor Green                    
                    }
                    Pause

                    #MODIFICA devices
                    Write-Host "Aggiornamento devices.config"  -ForegroundColor White -BackgroundColor Blue
                    Write-Log -Level Info "Aggiornamento devices.config"
                    Write-Output ""
                    try{
                        #percorso completo al file device
                        [xml]$device = [xml](Get-Content $uncPathClientPos"\devices.config")

                        $ns = New-Object System.Xml.XmlNamespaceManager($device.NameTable)
                        $ns.AddNamespace("ns", $device.DocumentElement.NamespaceURI)
                        $object = $device.SelectSingleNode("//ns:object[@name='FiscalPrinterDevice']", $ns)

                        foreach($name in $object.property){
                                    if($Global:RTMODE -eq "RT"){
                                        if($name.name -eq "SendVat"){
                                            $name.SetAttribute('value',"true")
                                            Write-Log -Level Info "MODALITA' RT"
                                            Write-Host "MODALITA' RT" -ForegroundColor Cyan
                                            Write-Host "Aggiornato SendVat: TRUE" -ForegroundColor Yellow
                                            Write-Log -Level Info "Impostato SendVat a TRUE"
                                    }
                                    if($name.name -eq "PrintRTQRCode"){
                                            $name.SetAttribute('value',"true")
                                            Write-Log -Level Info "MODALITA' RT"
                                            Write-Host "MODALITA' RT" -ForegroundColor Cyan
                                            Write-Host "Aggiornato PrintRTQRBarcode: TRUE" -ForegroundColor Yellow
                                            Write-Log -Level Info "Impostato PrintRTQRCode a TRUE"
                                    }
                                }
                                if($Global:RTMODE -eq "MF"){
                                    if($name.name -eq "SendVat"){
                                        $name.SetAttribute('value',"false")
                                        Write-Log -Level Info "MODALITA' RT"
                                        Write-Host "MODALITA' RT" -ForegroundColor Cyan
                                        Write-Host "Aggiornato SendVat: TRUE" -ForegroundColor Yellow
                                        Write-Log -Level Info "Impostato SendVat a TRUE"
                                }
                                if($name.name -eq "PrintBarcode"){
                                        $name.SetAttribute('value',"true")
                                        Write-Log -Level Info "MODALITA' MF"
                                        Write-Host "MODALITA' MF" -ForegroundColor Cyan
                                        Write-Host "Aggiornato PrintBarcode: TRUE" -ForegroundColor Yellow
                                        Write-Log -Level Info "Impostato PrintBarcode a TRUE"
                                }
                            }

                        }
                    }
                    catch{
                        Write-Host "Impossibile modificare il file devices..." -ForegroundColor Red
                        Write-Log -Level Error "Impossibile modificare il file devices..."
                        Pause
                        break
                        Clear-Host
                    }
                    finally{
                    
                        $device.Save($uncPathClientPos+"\devices.config")
                        Write-Host "File devices.config salvato..." -ForegroundColor Green
                        Write-Log -Level Info "File devices.config salvato"
                        Write-Host "$TAB_CHR FINITO" -ForegroundColor Black -BackgroundColor Green                    
                    }
                    Pause
                    Clear-Host
                    $currPos++
                    #rimuove l'unita' J, per poter mappare la successiva cassa
                    Get-PSDrive J | Remove-PSDrive
                }
                Write-Log -Level Info "Fine operazione 4 - UPDATE ClientPOS"
                menu
            }
            default
            {
                Write-Output ""
                Write-Output "Il valore inserito non è corretto"
                Write-Output ""
                Write-Output "L'AGGIORNAMENTO VERRA' INTERROTTO."
                Exit
            }
        }
    }
    else
    {
        Write-Output ""
        Write-Host "L'AGGIORNAMENTO VERRA' INTERROTTO." -ForegroundColor Black -BackgroundColor Red
        Exit
    }
}
