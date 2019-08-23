# DelaproInstallNet

Powershell Installationsscript um Delapro im Netzwerk unter Windows 10 zu installieren. Hier finden sich nur die netzwerkspezifischen Scripte. Für die eigentliche Installation wird auf die [DelaproInstall-Sktipte](https://github.com/Delapro/DelaproInstall) zurückgegriffen.

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
```

