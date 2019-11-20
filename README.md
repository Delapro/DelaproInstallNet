# DelaproInstallNet

Powershell Installationsscript um Delapro im Netzwerk unter Windows 10 zu installieren. Hier finden sich nur die netzwerkspezifischen Scripte. Für die eigentliche Installation wird auf die [DelaproInstall-Skripte](https://github.com/Delapro/DelaproInstall) zurückgegriffen.

Hat man die normalen DelaproInstall-Skripte geladen, kann man mit dem Befehl 

```Powershell
Invoke-DelaproInstallNetDownloadAndInit
```

die Netzwerkscripte automatisch nachladen. Danach stehen einem die Funktionen zur Verfügung.

> **Hinweis zu älteren Versionen**
>
> Die Scripts werden ausschließlich unter Windows 10 1803 und neuer sowie Server 2016 und neuer getestet.

## Hinweis zu SMB1

Wann immer möglich wird versucht ohne SMB1 auszukommen. Es sei denn es ist im Netz ein Gerät zwingend darauf angewiesen.

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

## Schlanke Installation im Netz

Wenn man die Installation der Demoversion auf den einzelnen Stationen vermeiden möchte, so benötigt man doch gewisse Druckerinstallationen.

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

# Ghostscript in GhostPDF.BAT korrekt setzen
Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\GHOSTPDF.BAT" -Verbose
If (Test-Path "$($DLPPath)\LASER\GHOSTPDFX.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\GHOSTPDFX.BAT" -Verbose
}
If (Test-Path "$($DLPPath)\LASER\XGHOSTPDF.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\XGHOSTPDF.BAT" -Verbose
}
If (Test-Path "$($DLPPath)\LASER\XXGHOSTPDF.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\XXGHOSTPDF.BAT" -Verbose
}
If (Test-Path "$($DLPPath)\LASER\XGHOSTPDFX.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\XGHOSTPDFX.BAT" -Verbose
}
If (Test-Path "$($DLPPath)\LASER\XXGHOSTPDFX.BAT") {
    Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER\XXGHOSTPDFX.BAT" -Verbose
}

```

