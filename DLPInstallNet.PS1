# DLPInstallNet.PS1
#
# Hauptmodul, von dem aus die anderen Module geladen werden
#

# Freigabename
$easyShare = "easy"
$easySharePath = "C:\easy"

# Benutzergruppenname
$easyGroup = "easy"

# Benutzer zum Testen
$easyTester = "easyTester"
$easyTesterPW = "easy1"

# Arbeitsgruppe
$peerWorkgroup = "WORKGROUP"

$PeerServerName = "PeerServer.local"

# Firewallregeln
$FirewallNetshareGroup = "File and Printer Sharing"
$FirewallNetshareGroup = "Datei- und Druckerfreigabe"

$FirewallNetworkDiscoveryGroup = "Network Discovery"
$FirewallNetworkDiscoveryGroup = "Netzwerkerkennung"

$FirewallRemoteDesktop = "Remote Desktop"
$FirewallRemoteDesktop = "Remotedesktop"

# Module einbinden
. .\DLPInstallCommon.PS1
. .\DLPInstallServer.PS1
. .\DLPInstallClient.PS1

Function Refresh-SMBMapping {

}

# Um Probleme zu lösen
Get-WinEvent -LogName 'Microsoft-Windows-SMBServer/Operational' | Select-Object -First 10
# oder alles:
Get-WinEvent -LogName 'Microsoft-Windows-SMBServer/*' | Select-Object -First 10

# am Client:
Get-WinEvent -LogName 'Microsoft-Windows-SMBClient/*' | Select-Object -First 10


# Probleme mit verlorenen Paketen bei Netzwerkkarten prüfen:
Get-NetAdapterStatistics|select *error*, *discard* |fl *

# Netzwerkadaptereinstellungen bei Problemen beachten:
Get-NetAdapterAdvancedProperty

# Dienste überprüfen
Get-Service Netlogon
Get-Service LanmanWorkstation
# KB 4034314:
# als Ersatz für BROWSER-Dienst, damit im Explorer die Netzwerkumgebung funktioniert (leider nicht Net View):
Get-Service FDResPub  # Function Discovery Resource Publication, Funktionssuche-Ressourcenveröffentlichung

# beim Server
Get-Service LanmanServer

# Credentials 
rundll32.exe keymgr.dll,KRShowKeyMgr
# bzw.
cmdkey.exe /list
# auch 
control Userpasswords2

# fürs Troubleshooting kann man sich hier ein paar Tipps holen:
# https://wiki.archlinux.org/index.php/Samba#Client


# Oldschool Drive-Mapping $true=persistent:
(New-Object -ComObject WScript.Network).MapNetworkDrive('Z:','\\server\folder',$true)
# neue Variante:
New-SmbMapping
# globale Variante für alle Benutzer und Dienste:
New-SmbGlobalMapping


# Datensicherheit und Performance: New-Mapping -UseWriteThrough:
# New-SmbMapping -LocalPath 'N:' -RemotePath '\\Server\Share' -UseWriteThrough $True
# Allerdings gibt es kein Set-SmbMapping, d. h. wenn man die UseWriteTrough Eigenschaft 
# an einer bestehenden Verbindung ändern möchte, muss diese zuerst aufgehoben und
# neu gesetzt werden!
# https://www.starwindsoftware.com/blog/windows-server-2019-introduces-a-new-smb-mapping-option-usewritethrough

# Ersatz für Net view: funktioniert aber nur wenn WinRM aktiv ist, also TrustedHost einrichten!
# $sv = New-CimSession -Computername Servername
# Get-SMBShare -CimInstance $sv


# bei Problemen mit Zugriffsrechten, aktuelle Einstellungen sichern:
# Get-SmbShare | Get-SmbShareAccess | Export-Clixml -Path C:\Temp\SmbPermissions.xml
# und wieder zurücksichern
# $PermissionList = Import-Clixml -Path C:\Temp\SmbPermissions.xml
# foreach($Permission in $PermissionList){
#     Grant-SmbShareAccess -Name $Permission.Name -AccountName $Permission.AccountName -AccessRight $PermissionList.AccessRight
# }

* EOF: DLPInstallNet.PS1