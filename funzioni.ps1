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
        $DataRows = Invoke-Sqlcmd -ServerInstance $Global:sqlserver -Database 'OrangeServer' -Query "SELECT ipaddress,description,code FROM client WHERE code in($array_POS)"
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
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║1)BackUp Orange Admin         ║"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║2)BackUp ClientPOS            ║"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║3)BackUp AeviPay              ║"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║4)Update ClientPOS            ║"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║5)Update AeviPay              ║"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║6)Query DB                    ║"
    # Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    # Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║8)Agg. completo POS           ║" -ForegroundColor White -BackgroundColor Green
    # Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    # Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║9)Agg. completo POS [Auto]    ║" -ForegroundColor White -BackgroundColor Blue
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║10)Ripristino ClientPOS       ║" -ForegroundColor Black -BackgroundColor Gray
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║11)Installazione driver RT-ONE║" -ForegroundColor Black -BackgroundColor Cyan
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR╠══════════════════════════════╣"
    Write-Host "$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR$TAB_CHR║12)Cambia SENDVAT             ║" -ForegroundColor Black -BackgroundColor Red
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
                #BCK ORANGE ADMIN
                    Write-Log -Level Info "Inzio operazione 1 - BCK Orange Admin"
                    #path alla cartella Orange Admin
                    $uncPathOrangeAdmin = "C:\Orange\Admin"
                    $pathDBAdmin="C:\Orange\DB"
                    $backDB="C:\Orange\bck_DB_"+$today
                    #path cartella backup Orange Admin
                    $bckAdmin ="C:\Orange\bck_Admin_"+$today
                    
                    Write-Host "BACKUP ORANGE ADMIN" -ForegroundColor Black -BackgroundColor Yellow
                    backup $uncPathOrangeAdmin $bckAdmin
                    Write-Host "Backup DB Orange ADMIN" -ForegroundColor Black -BackgroundColor Yellow
                    ServiceStopper('MSSQL$SQLEXPRESS')
                    backup $pathDBAdmin $backDB
                    ServiceStarter('MSSQL$SQLEXPRESS')
                    Pause
                    Clear-Host
                    Write-Log -Level Info "Fine operazione 1 - BCK Orange Admin"
                    menu
            }       
            2 
            {
                Write-Log -Level Info "Inizio operazione 2 - BCK ClientPOS"
                Write-Host "Numero casse da fare il backup: $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                Pause
                Clear-Host
                $currPos=1
                foreach ($ip in $RecordPOS) 
                {
                    Write-Host "Backup cassa $currPos di $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                    Write-Log -Level Info ("Backup cassa $currPos di $totalPOS")
                    Write-Log -Level Info ("CASSA: "+$ip.ipaddress)
                    #path remoto alla cassa
                    $uncPathPOS = "\\" + $ip.ipaddress + "\c$"
                    #path remoto alla cartella Orange
                    $uncPathOrange = "J:\Orange"

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
                        Clear-Host
                        break   
                    }
                    Pause
                    #BACKUP ClientPOS

                    #path remoto alla cartella ClientPOS
                    $uncPathClientPos = "J:\Orange\ClientPOS"
                    #percorso completo alla cartella di backup, composta da "bck_ClientPOS_yyyyMMdd"
                    $backupFolderClientPOS ="J:\Orange\bck_ClientPOS_"+$today
                    Write-Host "BACKUP ClientPOS" -ForegroundColor Black -BackgroundColor Yellow
                    backup $uncPathClientPOS $backupFolderClientPOS
                    Pause
                    Clear-Host
                    $currPos++
                    #rimuove l'unita' J, per poter mappare la successiva cassa
                    Get-PSDrive J | Remove-PSDrive
                }
                Write-Log -Level Info "Fine operazione 2 - BCK ClientPOS"
                menu
            }
            3
            {
                Write-Log -Level Info "Inizio operazione 3 - BCK AeviPay"
                Write-Host "Numero casse da aggiornare: $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                Pause
                Clear-Host
                $currPos=1  
                foreach ($ip in $RecordPOS) 
                {
                    #path remoto alla cassa
                    Write-Host "Aggiornamento cassa $currPos di $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                    Write-Log -Level Info ("Aggiornamento cassa $currPos di $totalPOS")
                    Write-Log -Level Info ("CASSA: "+$ip.ipaddress)
                    $uncPathPOS = "\\" + $ip.ipaddress + "\c$"

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
                    #BACKUP AeviPay

                    #path remoto alla cartella AeviPay
                    $uncPathAevi = "J:\AeviPay"
                    #percorso completo alla cartella di backup, composta da "bck_AeviPay_yyyyMMdd"
                    $backupFolderAevi ="J:\bck_AeviPay_"+$today
                    Write-Host "BACKUP AEVIPAY" -ForegroundColor Black -BackgroundColor Yellow
                    backup $uncPathAevi $backupFolderAevi
                    Pause
                    Clear-Host
                    $currPos++
                    #rimuove l'unita' J, per poter mappare la successiva cassa
                    Get-PSDrive J | Remove-PSDrive
                }
                Write-Log -Level Info "Fine operazione 3 - BCK AeviPay"
                menu
            }
            4
            {
                Write-Log -Level Info "Inizio operazione 4 - UPDATE ClientPOS"
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
                    $uncPathClientPos ="$uncPathOrange\ClientPOS"

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
                    Clear-Host
                    $currPos++
                    #rimuove l'unita' J, per poter mappare la successiva cassa
                    Get-PSDrive J | Remove-PSDrive
                }
                Write-Log -Level Info "Fine operazione 4 - UPDATE ClientPOS"
                menu
            }
            5
            {
                Write-Log -Level Info "Inizio operazione 5 - UPDATE AeviPay"
                Write-Host "Numero casse da aggiornare: $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                Pause
                Clear-Host
                $currPos=1
                foreach ($ip in $RecordPOS) 
                {
                    Write-Host "Aggiornamento cassa $currPos di $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                    Write-Log -Level Info ("Aggiornamento cassa $currPos di $totalPOS")
                    #path remoto alla cassa
                    $uncPathPOS = "\\" + $ip.ipaddress + "\c$"
                    $ipPOS="\\"+$ip.ipaddress
                    #path remoto alla cartella Orange
                    $uncPathAevi = "J:\AeviPay"

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
                        Write-Host ("Creato collegamento con la cassa: "+$ip.ipaddress) -ForegroundColor Black -BackgroundColor Green  
                        Write-Log -Level Info ("Creato collegamento con la cassa: "+$ip.ipaddress)
                    }
                    catch{
                        Clear-Host
                        Write-Host "Impossibile creare il disco di rete J, controllare i parametri e che il disco non sia gia' presente (scollegarlo nel caso)" -ForegroundColor Red
                        Write-Log -Level Error "Impossibile creare il disco di rete J, controllare i parametri e che il disco non sia gia' presente (scollegarlo nel caso)"
                        Pause
                        Clear-Host
                        break
                    }
                    Pause
                    #UPDATE AeviPay

                    #esegue le operazioni di aggiornamento cassa
                    Write-Output "$TAB_CHR Passo $currStep di $steps"
                    $sourceAevi= "$currentDir\Aevipay"
                    update $sourceAevi $uncPathAevi
                    Pause

                    #MODIFICA XPaySocketTunnelService
                    Write-Host "Aggiornamento XPaySocketTunnelService.exe.config"  -ForegroundColor White -BackgroundColor Blue
                    Write-Log -Level Info "Aggiornamento XPaySocketTunnelService.exe.config"
                        Write-Output ""
                    try{
                        #percorso completo al file XPaySocketTunnelService
                        $AeviPayXml = [xml](Get-Content $uncPathAevi"\X.Pay_Service_LAN\Service_1.0.4.12\XPaySocketTunnelService.exe.config")
                        $last = [string]$ip.ipaddress
                        $address="192.168.1"+$StoreCod.Substring(2)+".1"+$last.Substring($last.Length-2)
                        Write-Host ("Indirizzo terminale Aevipay:"+ $address) -ForegroundColor White -BackgroundColor DarkRed
                        Write-Log -Level Info ("Indirizzo terminale Aevipay:"+ $address)

                        $Channel = $AeviPayXml.configuration.XPaySocketTunnelConfig.Channels.Channel.Item(0)
                        $Channel.SetAttribute('TargetIpAddr',$address)
                    }
                    catch{
                        Clear-Host
                        Write-Host "Impossibile modificare il file XPaySocketTunnelService.exe.config..." -ForegroundColor Red
                        Write-Log -Level Error "Impossibile modificare il file XPaySocketTunnelService.exe.config"
                        Pause
                        break
                        Clear-Host     
                    }
                    finally{

                        $AeviPayXml.Save($uncPathAevi+"\X.Pay_Service_LAN\Service_1.0.4.12\XPaySocketTunnelService.exe.config")
    
                        Write-Host "File XPaySocketTunnelService.exe.config salvato..." -ForegroundColor Green
                        Write-Log -Level Info "File XPaySocketTunnelService.exe.config salvato"

                        try{
                            .\PsExec.exe $ipPOS -h -i -d -u $Global:pos_username -p $Global:pos_password -w "C:\aevipay\X.Pay_Service_LAN\Service_1.0.4.12\" cmd /c "C:\aevipay\X.Pay_Service_LAN\Service_1.0.4.12\InstallService.bat"
                            Write-Log -Level Info "Installato il servizio AeviPay"
                            .\PsExec.exe $ipPOS -h -i -d -u $Global:pos_username -p $Global:pos_password -w "C:\aevipay\X.Pay_Service_LAN\Service_1.0.4.12\" cmd /c "C:\aevipay\X.Pay_Service_LAN\Service_1.0.4.12\RestartService.bat"
                            Write-Log -Level Info "Riavviato il servizio AeviPay"
                        }

                        catch{
                                Write-Host "Errore nel installare il servizio. Eseguire installazione manualmente" -ForegroundColor Red
                                Write-Log -Level Error "Errore nel installare il servizio. Eseguire installazione manualmente"
                        }

                        Write-Host "$TAB_CHR FINITO" -ForegroundColor Black -BackgroundColor Green                        
                    }
                    Pause
                    Clear-Host
                    $currPos++
                    #rimuove l'unita' J, per poter mappare la successiva cassa
                    Get-PSDrive J | Remove-PSDrive
                }
                Write-Log -Level Info "Fine operazione 5 - UPDATE AeviPay"
                menu
            }
            6
            {   
                Write-Log -Level Info "Inizio operazione 6 - Query"
                #ESECUZIONE
                Write-Host "Esecuzione QUERY" -ForegroundColor White -BackgroundColor Blue
                Write-Log -Level Info "Esecuzione QUERY"
                Write-Output ""
                $dbname = "ONESTORE_$StoreCod"
                try{

                    Invoke-Sqlcmd -InputFile "$currentDir\SQL\scriptOrange.sql" -ServerInstance $Global:sqlserver -Database "OrangeServer" -Username $Global:sqluser -Password $Global:sqlpassword -Verbose
                    Invoke-Sqlcmd -InputFile "$currentDir\SQL\scriptOne.sql" -ServerInstance $Global:sqlserver -Database $dbname -Username $Global:sqluser -Password $Global:sqlpassword -Verbose
                   
                    Write-Host "$TAB_CHR FINITO" -ForegroundColor Black -BackgroundColor Green
                    Write-Host "Aggiornamento DB eseguito con successo" -ForegroundColor Green
                    Write-Log -Level Info "Aggiornamento DB eseguito con successo"
                    $currStep++
                }
                catch{

                    Clear-Host
                    Write-Host "Impossibile eseguire la query" -ForegroundColor Red
                    Write-Log -Level Error "Impossibile eseguire la query"
                    Pause
                    break
                    Clear-Host
                }
                finally{

                    Push-Location -Path $currentDir
                    Pause
                    Clear-Host
                    Write-Log -Level Info "Fine operazione 6 - Query"
                    menu
                }                        
            }
            7
            {
                Write-Log -Level Warn "Cancellato disco di rete J"
                net use J: /delete
                Clear-Host
                menu
            }
            10 
            {
                #Restore Backup

                Write-Host "Restore BACKUP" -ForegroundColor Black -BackgroundColor Yellow
                #indirizzo POS
                $ipPOS = Read-Host 'Inserire indirizzo ip postazione'
                Write-Host "Ripristino BACKUP" -ForegroundColor Black -BackgroundColor Yellow
                restore($ipPOS)
                Pause
                Clear-Host
                menu
            }
            11
            {
                Write-Host "Numero casse selezionate: $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                Pause
                Clear-Host
                $currPos=1
                foreach ($ip in $RecordPOS) 
                {
                    Write-Host "Installazione driver della cassa $currPos di $totalPOS" -ForegroundColor Black -BackgroundColor Yellow
                    Write-Log -Level Info ("Installazione driver della cassa $currPos di $totalPOS")
                    #region CASSE SET PARAMS
                    #path remoto alla cassa
                    $uncPathPOS = "\\" + $ip.ipaddress + "\c$"

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
                        Clear-Host
                        break
                    }
                    Pause

                   #install OPOS RTONE
                   Write-Host "Installazione driver RT-ONE e RT-TOOLS" -ForegroundColor Black -BackgroundColor Yellow
                   Write-Log -Level Info "Installazione driver RT-ONE e RT-TOOLS"
                   Write-Log -Level Info ("CASSA: "+$ip.ipaddress)           
                   $ipPOS ="\\"+$ip.ipaddress
                   $sourceDriver= "$currentDir\Driver"
                   $dest="J:\Temp\OPOS"
                   update $sourceDriver $dest   
                   .\PsExec.exe $ipPOS -i -s -d -u $Global:pos_username -p $Global:pos_password cmd /c "C:\Temp\OPOS\OPOS\Opos_RTOne_1.3.19_setup.exe /silent"   
                   Start-Sleep -Seconds 5   
                   .\PsExec.exe $ipPOS -i -s -d -u $Global:pos_username -p $Global:pos_password cmd /c "taskkill /IM cmd.exe /f "   
                   .\PsExec.exe $ipPOS -i -s -d -u $Global:pos_username -p $Global:pos_password cmd /c "taskkill /IM OPOSConfigurator_x86.exe /f "
                   Write-Log -Level Info "Installato driver"   
                   .\PsExec.exe $ipPOS -i -s -u $Global:pos_username -p $Global:pos_password regedit.exe /s "C:\Temp\OPOS\OPOS\RTONE.reg"
                   Write-Log -Level Info "Applicato chiavi di registro"   
                   .\PsExec.exe $ipPOS -i -s -d -u $Global:pos_username -p $Global:pos_password cmd /c "C:\Temp\OPOS\OPOS\Register.bat"
				   
                   .\PsExec.exe $ipPOS -i -s -d -u $Global:pos_username -p $Global:pos_password cmd /c "C:\Temp\OPOS\RT-Tools.msi /quiet"
                   Write-Log -Level Info "Installato RT-TOOLS"   
                   Write-Host "FINITO" -ForegroundColor Black -BackgroundColor Green

                    $currPos++
                    #rimuove l'unita' J, per poter mappare la successiva cassa
                    Get-PSDrive J | Remove-PSDrive
		    Pause
                    Clear-Host
                }
                Clear-Host
                menu
            }
            12
            {
                Write-Log -Level Info "Inizio opzione 12 - Cambio MF/RT"
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
                    $uncPathClientPos ="$uncPathOrange\ClientPOS"

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
                        Clear-Host
                        break
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
                        $object.InsertAfter()
                        foreach($name in $object.property){
                                if($name.name -eq "SendVat"){
                                    if($name.value -eq "false"){
                                        $name.SetAttribute('value',"true")
                                        Write-Log -Level Info "MODALITA' RT"
                                        Write-Host "MODALITA' RT" -ForegroundColor Cyan
                                        Write-Host "Aggiornato SendVat: TRUE" -ForegroundColor Yellow
                                        Write-Log -Level Info "Impostato SendVat a TRUE"
                                    }
                                }
                                if($name.name -eq "PrintBarcode"){
                                    if($name.value -eq "true"){
                                        $name.SetAttribute('value',"false")
                                        Write-Log -Level Info "MODALITA' RT"
                                        Write-Host "MODALITA' RT" -ForegroundColor Cyan
                                        Write-Host "Aggiornato PrintBarcode: FALSE" -ForegroundColor Yellow
                                        Write-Log -Level Info "Impostato PrintBarcode a FALSE"
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
                Write-Log -Level Info "Fine opzione 12 - Cambio MF/RT"
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
