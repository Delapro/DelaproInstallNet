# Beispiel wie ein Client eingerichtet werden kann

Es muss das Netzlaufwerk N: eingerichtet sein mit Setup-Verzeichnis für bestimmte Daten wie z. B. Druckertreiber. Es werden nur die reinen Standard-Delapro-Optionen installiert.
Der lokale Programmverteiler wird ausgetauscht mit speziellen Hinweisen auf das Netzlaufwerk. Combit-MAPI-Proxy wird explizit übers Netzlaufwerk registriert.
Drucker wird V3-Treiber für korrekte Schachtunterstützung geladen.

Dateien für Progvert und Netzlaufwerkverbinden siehe Unterverzeichnis: Client-Einrichtung-Dateien

```Powershell
# ================================== Station Setup ================================
$DelaproInstParameter = @{
	DlpPath = 'C:\Delapro'
	DlpGamePath = 'C:\Delagame'
	DlpInstPath = $DlpInstPath
	InstallSwitch = @('Main', 'Image', 'Chart', 'Zert', 'TeamViewer', 'AnyDesk', 'Mailer',
					  'eDocPrintPro', 'AntiMalware')
}


Install-Delapro @DelaproInstParameter
net use N: \\core\easy /SAVECRED /PERSTITENT:YES
# Daten wie oben für easyNetz-Benutzer

# Outlook 64Bit:
$DelaproPath='N:\Delapro'
If ((Get-DefaultEMailClient) -eq 'Microsoft Outlook, x64') {
  # $DLPPath muss auf N:\Delapro lauten
  Register-CombitMAPIProxy -Verbose -DelaproPath $DlpPath
}

# Verknüpfung auf Desktop auf Laufwerk N: abändern

# NetzLWVerbinden.BAT von N:\Setup in c:\Delapro kopieren
copy N:\setup\NetzLWVerbinden.BAT
# PROGVERT von N:\Setup auf lokales Delapro kopieren
# F2 : Bitte Netz-Delapro starten                        
# F3 :                                                   
# F4 : Falls Netz-Delapro nicht aufrufbar sein sollte,   
# F5 : bitte Netzwerkverbindung zum Server prüfen!       
# F6 :                                                   
# F7 :                                                   
# F8 : Netzlaufwerk verbinden                            
# F9 :                                                   
#
#  Netzlaufwerk verbinden, sieht so aus, der Rest ist leer:
#            Eintrag Netzlaufwerk verbinden                         
#     Programmaufruf CALL NetzLWVerbinden.BAT                       
# 
copy N:\setup\PROGVERT.DBF


# Druckertreiber abklären
get-printer -Name 'HP7E66D4 (HP OfficeJet Pro 9010 series)'
get-printer -Name 'HP26F3FE (HP LaserJet Pro 4002)'
If (((get-printer -Name 'HP26F3FE (HP LaserJet Pro 4002)').Drivername) -ne 'HP LaserJet Pro 4001 4002 4003 4004 PCL 6 (V3)') {
  # Treiber hinzufügen: 
  # klappt nicht: Add-PrinterDriver -name 'HP LaserJet Pro 4001 4002 4003 4004 PCL 6 (V3)' -InfPath 'N:\Setup\LaserJetPro 4002dn -Type 3 Treiber\HP_LJ4001-4004\HP_LJ4001-4004_V3\hpyo0274_x64.inf'
  pnputil -i -a 'N:\Setup\LaserJetPro 4002dn -Type 3 Treiber\HP_LJ4001-4004\HP_LJ4001-4004_V3\hpyo0274_x64.inf'
  # Treiber Warteschlange zuordnen
  Set-Printer -Name 'HP26F3FE (HP LaserJet Pro 4002)' -Drivername 'HP LaserJet Pro 4001 4002 4003 4004 PCL 6 (V3)'
}
# Check
(get-printer -Name 'HP26F3FE (HP LaserJet Pro 4002)').Drivername -eq 'HP LaserJet Pro 4001 4002 4003 4004 PCL 6 (V3)'
# Duplex rausnehmen!
# Druckereinstellungen speichern
# RUNDLL32 PRINTUI.DLL,PrintUIEntry /Ss /n "HP26F3FE (HP LaserJet Pro 4002)" /a "N:\Setup\LaserjetPro4002-Einstellungen.dat"
# Einstellungen setzen, wichtig u am Ende! Sonst gibts Fehler 0x0000000c, siehe auch: https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/ee624057(v=ws.11)?redirectedfrom=MSDN
# RUNDLL32 PRINTUI.DLL,PrintUIEntry /Sr /n "HP26F3FE (HP LaserJet Pro 4002)" /a "N:\Setup\LaserjetPro4002-Einstellungen.dat" u
# gegebenfalls Delapro-Schachtzuordnungen setzen

# SMB Cache Einstellungen und PING aktivieren
Set-Location C:\Temp
. Invoke-DelaproInstallNetDownloadAndInit
# Firewallregeln
$FirewallNetshareGroup = "File and Printer Sharing"
$FirewallNetshareGroup = "Datei- und Druckerfreigabe"

$FirewallNetworkDiscoveryGroup = "Network Discovery"
$FirewallNetworkDiscoveryGroup = "Netzwerkerkennung"

$FirewallRemoteDesktop = "Remote Desktop"
$FirewallRemoteDesktop = "Remotedesktop"
If (-Not (Test-NetworkDiscoveryFirewall)) {
	Enable-NetworkDiscoveryFirewallPorts
}

Set-SmbClientConfiguration -OplocksDisabled $true -Force
Set-SmbClientConfiguration -UseOpportunisticLocking $false -Force

# zusätzlich vielleicht, wird für Suchserver benötigt:
Set-SmbClientConfiguration -DirectoryCacheLifetime 0 -Force
Set-SmbClientConfiguration -FileInfoCacheLifetime 0 -Force
Set-SmbClientConfiguration -FileNotFoundCacheLifetime 0 -Force

```
