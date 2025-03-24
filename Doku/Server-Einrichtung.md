PeerServer Vorgehensweise, Neueinrichtung mit späterer Datenübernahme

+ evtl. Server benennen <Code>Rename-Computer -NewName Abrechnung</Code>
+ Prüfen von <Code>Get-NetConnectionProfile</Code>
+ korrekte Netzwerkkartengeschwindigkeit checken <Code>(Get-NetAdapter |where status -eq up)|select Name, Interfacedescription, ifindex, linkspeed</Code>
+ Delapro Demoversion auf C: installieren
+ Netzlaufwerk (N:) einrichten
+ Rechte testen, gegebenfalls Rechner neu starten: runas /user:easyTester /profile cmd
+ Ordner Delapro und Delagame nach N: verschieben
+ neuen Ordner C:\Delapro\Export\PDF\Temp einrichten
+ in C:\Delapro folgende Dateien kopieren: PROGVERT.DBF (speziell von dieser Doku), DLP_MAIN.INI, DELAPRO.EXE, DLPHD.ICO
+ Verknüpfung auf dem Desktop auf N:\DELAPRO ändern, mit Icon auf C:\DELAPRO\DLPHD.ICO
+ NetzLWVerbinden.BAT für \\localhost\easy einrichten
+ N:\SETUP\CLIENT und N:\SETUP\SERVER anlegen, Serverinfos in ServerInfo.TXT (IP-Adresse, Hostname, Netz-Laufwerk, Gateway, DHCP, DNS-Infos, Benutzer) ablegen

+ $DLPPath=Get-DelaproPath; $DlpGamePath=Get-DelaproPath -Delagame; $DLPPath; DLPGamePath
+ Import-LastDelaproBackup -DestinationPath $DlpPath -Verbose
+ Update-DelaproGhostscript -PathDelaproGhostscript "$($DLPPath)\LASER" -Verbose
+ Invoke-CleanupDelapro $DlpPath -Verbose
+ Install-DelaproXMLFormulardateien -DelaproPath $DlpPath -DelaGamePath $DlpGamePath
+ SearchServerExceptions setzen
