# DelaproInstallNet

Powershell Installationsscript um Delapro im Netzwerk unter Windows 10 zu installieren. Hier finden sich nur die netzwerkspezifischen Scripte. Für die eigentliche Installation wird auf die [DelaproInstall-Skripte](https://github.com/Delapro/DelaproInstall) zurückgegriffen.

Hat man die normalen DelaproInstall-Skripte geladen, kann man mit dem Befehl 

```Powershell
# Dot-Sourcing damit die Funktionen zur Verfügung stehen!
. Invoke-DelaproInstallNetDownloadAndInit

# für einen besseren Üblick ist es manchmal hilfreich zu wissen auf welchem
# Rechner man gerade ist, dadurch wird der COMPUTERNAME ausgegeben
Install-NetPrompt

# falls der COMPUTERNAME mal was nicht hergibt, kann man auch die Anzeige
# selber bestimmen
Install-NetPrompt -PromptExt 'SERVER'
```

die Netzwerkscripte automatisch nachladen. Danach stehen einem die Funktionen zur Verfügung.

> **Hinweis zu älteren Versionen**
>
> Die Scripts werden ausschließlich unter Windows 10 1803 und neuer sowie Server 2016 und neuer getestet.

## Hinweis zu SMB1

Wann immer möglich wird versucht ohne SMB1 auszukommen. Es sei denn es ist im Netz ein Gerät zwingend darauf angewiesen.

## Umstellung von Einzelplatz- auf Netzwerkversion

Verschiebung von \DELAPRO und \DELAGAME in \easy. Verknüpfung umstellen.

Bitte beachten, dass GHOST*.BAT und XGHOST*.BAT-Dateien angepasst werden müssen, damit die Pfade für die PDF-Erzeugung stimmen!

Auf einem Peer-Server sollte ein leeres C:\Delapro-Verzeichnis zurückbleiben, mit dem Hinweis auf den Umzug aufs Netz. Gleichzeitig muss aber der Pfad C:\DELAPRO\EXPORT\PDF\TEMP vorhanden sein, damit Ghostscript korrekt funktioniert. Auch sollte die DLPHD.ICO in das Verzeichnis kopiert werden und der Desktoplink darauf verweisen, damit immer das korrekte Symbol angezeigt wird.

## bei Problemen
```cmd
nbtstat.exe /a $PeerServerName
```

```Powershell
Resolve-DnsName $PeerServerName -LlmnrNetbiosOnly

Resolve-DnsName (Hostname.exe) -LlmnrNetbiosOnly

Get-DnsClient

# Connectionsuffix ermitteln
(Get-DnsClient -InterfaceIndex ((Get-NetConnectionProfile)| select -ExpandProperty Interfaceindex)).ConnectionSpecificSuffix

# Network Location Awareness
Get-WinEvent -LogName "Microsoft-Windows-NlaSvc/Operational"|select -First 5 | ft -Wrap
# Netzwerkprofile
Get-WinEvent -LogName "Microsoft-Windows-NetworkProfile/Operational"|select -First 5 | ft -Wrap
# NCSI, Internetkonnektivität prüfen
Get-WinEvent -LogName "Microsoft-Windows-NCSI/Operational"|select -First 5 | ft -Wrap
```

### Netzwerkpakete mitschneiden

Bei größeren Problemen bei der Netzwerkkommunikation bietet sich auch ein Netzwerkpaketmitschnitt an.

Für diesen Fall richten wir hier zwei Verknüpfungen auf dem Desktop ein. Einmal um einen Mitschnitt zu starten und eine zweite um einen Mitschnitt zu beenden.

Die Einrichtung des Scripts benötigt keine Adminrechte, allerdings das Starten bzw. Beenden des Netzwerkpaketmitschnitts benötigt Adminrechte.

```Powershell
If (Test-Path C:\Temp) {
    Set-Location c:\Temp

    Invoke-DelaproInstallNetDownloadAndInit

    $psTrStart =@'
    . .\DLPInstallCommon.PS1
    Start-NetworkTrace -TraceFile "$((Resolve-Path .).Path)\$($env:COMPUTERNAME)_$((Get-Date -Format o).Replace(':','_')).etl"
'@

    $psTrStop = @'
    . .\DLPInstallCommon.PS1
    Stop-NetworkTrace
'@

    $psTrStart | Set-Content StartNetTrace.PS1
    $psTrStop  | Set-Content StopNetTrace.PS1

    New-PowershellScriptShortcut -Path .\StartNetTrace.PS1 -Admin -LinkFilename 'Trace starten' -Description 'Startet einen Netzwerkpaketmitschnitt' -Folder (Get-DesktopFolder)
    New-PowershellScriptShortcut -Path .\StopNetTrace.PS1 -Admin -LinkFilename 'Trace stoppen' -Description 'Stopt einen Netzwerkpaketmitschnitt' -Folder (Get-DesktopFolder)

}
```

Zum Analysieren der mitgeschnittenen Pakete verwendet man Wireshark. Damit die .etl-Dateien mit älteren Versionen von Wireshark geöffnet werden können, müssen diese vorher konvertiert werden.

```Powershell
# benötigten Konverter herunterladen
Install-Etl2PcapConverter
# Konvertierung aller ETL-Dateien im aktuellen Verzeichnis durchführen
dir *.etl | % {$_.name; .\etl2pcapng.exe $_.fullname $_.name.replace('.etl','.pcapng')}
```

Wenn man die Mitschnitte übertragen muss, macht es Sinn diese zu packen bzw. später wieder zu entpacken. Hier noch die passenden Routinen.

```Powershell
# zum Packen
dir *.etl | % {$_.Name; Compress-Archive -Path $_.fullname -CompressionLevel Optimal -DestinationPath $_.Name.Replace('.etl','.zip')}

# zum Entpacken
dir *.zip | Expand-Archive -Verbose -DestinationPath .
```

## Schlanke Installation im Netz

Wenn man die Installation der Demoversion auf den einzelnen Stationen vermeiden möchte, so benötigt man doch gewisse Druckerinstallationen.

Um nachfolgende Zeilen nicht ausführen zu müssen, kann man nun auch mit den Standard-Cmdlets die Clientinstallation mittels
```Powershell
Install-DelaproNetClientSetup
```
starten.

> **Hinweis**
> Damit nachfolgendes Script ausgeführt werden kann, müssen schon die Cmdlets von der Delapro-Standard-Installation geladen sein!

``` Powershell
# Verzeichnis für temporäre und Installationsdateien
$DlpInstPath = "C:\Temp\DelaproInstall\"
# Netzwerkverzeichnis fürs Abrechnungsprogramm
$DlpPath = "N:\Delapro"

# gegebenenfalls Netzlaufwerk verbinden!
# net use N: \\server\Freigabe

# DlpWinPr.EXE manuell installieren
Start-BitsTransfer https://easysoftware.de/download/dlpwinpr.exe
Start-Process -Wait .\dlpwinpr.exe -ArgumentList "-a", "-delaproPath=$($DlpPath)"

# was ist mit Image, Zert und Chart?

Install-eDocPrintPro -tempPath "$($DLPInstPath)"

Start-Process -Wait "C:\Program Files\Common Files\MAYComputer\eDocPrintPro\eDocPrintProUtil.EXE" -ArgumentList "/AddPrinter", '/Printer="DelaproPDF"', '/Driver="eDocPrintPro"', '/ProfilePath="C:\ProgramData\eDocPrintPro\DelaproPDF.ESFX"', "/Silent"
# WENN der Aufruf hier hängen bleibt, dann liegt es an fehlenden LOKALEN Adminrechten!!
# Rename-Printer -Name eDocPrintPro -NewName DelaproPDF
# durch Aufruf von eDocPrintProUtil.EXE sind zwei Druckertreiber vorhanden, deshalb den Standard eDocPrintPro löschen
Remove-Printer -Name eDocPrintPro

Install-DelaproMailPrinter -Verbose
Show-Printers

Disable-Windows10DefaultPrinterRoaming

# Ghostscript Version ermitteln
$gv = Get-Ghostscript
$gv
# Ghostversion prüfen, gegebenenfalls aktualisieren oder installieren
If ((@("gs9.00", "gs8.63", "gs8.64", "gs8.70", "gs8.71") -contains $gv[0].Name -and $gv.length -eq 1) -or ($gv.length -eq 0) -or ($null -eq $gv) {
    Install-Ghostscript -Verbose
}
# TODO: GhostPDF.BAT in LASER-Verzeichnis kopieren

# Ghostscript bei allen *GHOSTPDF*.BAT-Dateien setzen, indem man einfach den Pfad des Verzeichnis in dem die Dateien sind angibt, es werden also alle GHOSTPDF.BAT, XGHOSTPDFX.BAT und XXGHOSTPDFX.BAT-Dateien usw. aktualisiert
Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER" -Verbose

```

## Sonstiges

### Passwortänderung per Verknüpfung

Im einfachen Peernetz müssen bei Passwortänderungen diese synchron gehalten werden, damit dies komfortabel für den Benutzer möglich ist, kann man diese Verknüpfung verwenden:

```Powershell
# für den aktuellen Benutzer
$source=@'
$user = $env:USERNAME
Set-LocalUser -Name $user -Password (Get-Credential -UserName $user -Message 'Bitte neues Passwort eingeben').Password
'@

$source | Set-Content ChangePassword.PS1

New-PowershellScriptShortcut -Path .\ChangePassword.PS1 -Admin -LinkFilename 'Kennwort ändern' -Description 'Erlaubt das ändern des Kennworts des aktuellen Benutzers' -Folder (Get-DesktopFolder)

# für bestimmte Benutzer, benötigt Adminrechte:
$source=@'
$user=(Get-LocalUser | where enabled| Out-GridView -PassThru -Title "Bitte Benutzer zum Passwort ändern auswählen").name
Set-LocalUser -Name $user -Password (Get-Credential -UserName $user -Message 'Bitte neues Passwort eingeben').Password
'@
$source | Set-Content ChangePassword.PS1

New-PowershellScriptShortcut -Path .\ChangePassword.PS1 -Admin -LinkFilename 'Kennwort ändern' -Description 'Erlaubt das ändern des Kennworts eines bestimmten Benutzers' -Folder (Get-DesktopFolder -AllUsers)
```

### nicht verbundene Netzwerklaufwerke wieder verbinden

Das zu verbindende Netzlaufwerk muss zum Zeitpunkt der Erstellung des Scripts, welches über Save-NetDriveRefresh erstellt wird, verbunden sein.

```Powershell
# erzeugt eine PS1-Datei mit dem Wiederherstellungsscript
Save-NetDriveRefresh
New-PowershellScriptShortcut -Path .\RefreshNetDrive.PS1 -LinkFilename 'Netzlaufwerk-Verbindung wiederherstellen' -Description 'Stellt die Verbindung zu einem Netzlaufwerk wieder her.' -Folder (Get-DesktopFolder -CurrentUser)
```

### fehlende Netzlaufwerke wegen Adminrechten

siehe: https://docs.microsoft.com/en-us/troubleshoot/windows-client/networking/mapped-drives-not-available-from-elevated-command

### Stations-Umgebungsvariable setzen

DLP_PRGVRT=STATIONx setzen.

```Powershell
# [System.EnvironmentVariableTarget]::Process
# [System.EnvironmentVariableTarget]::User
[System.Environment]::SetEnvironmentVariable('DLP_PRGVRT', 'STATION1', [System.EnvironmentVariableTarget]::Machine)
```

### Geschwindigkeits- bzw. Performance- oder Bandbreiteneinstellungen

Prüfen, ob evtl. QoS-Restriktionen aktiv sind, mittels
```Powershell
Get-NetQosPolicy
```
siehe auch: https://woshub.com/limit-network-file-transfer-speed-windows/

```Powershell
Get-SmbBandwidthLimit
```
siehe auch: https://woshub.com/manage-windows-file-shares-with-powershell/
