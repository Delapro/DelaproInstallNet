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
# https://www.starwindsoftware.com/blog/windows-server-2019-introduces-a-new-smb-mapping-option-usewritethrough

* EOF: DLPInstallNet.PS1
