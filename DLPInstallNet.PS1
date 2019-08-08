# DLPInstallNet.PS1
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

# PeerServer einrichten
Function Install-easyPeerServer {
	[CmdletBinding()]
	Param(

	)

	# Hostname vom Server setzen?

	If (Test-EnergySaveSettings) {
		Disable-EnergySaveSettings
	}

	If (-Not (Test-ConnectionProfilePrivateOrDomain)) {
		Enable-ConnectionProfilePrivateOrDomain
	}

	If (-Not (Test-ICMPEcho)) {
		Enable-ICMPEcho
	}

	If (Test-SMB1Protocol) {
		Disable-SMB1Protocol
	}

	If (-Not (Test-SMBFirewall)) {
		Enable-SMBFirewallPorts
	}

	If (-Not (Test-NetworkSharingFirewallPorts)) {
		Enable-NetworkSharingFirewallPorts
	}

	If (-Not (Test-EasyEnvironmentVars)) {
		# Umgebungsvariablen setzen, dauerhaft!
		Set-EasyEnvironmentVars
	}

	If (-Not (Get-easyGroup)) {
		New-easyGroup -Group $easyGroup
	}

	If (-Not (Get-easyShare)) {
		New-easyShare
	}

	If (-Not (Get-easyTester -Username $easyTester)) {
		New-easyUser -Username $easyTester
	}

	Add-LocalGroupMember -Group $easyGroup -Member $easyTester

	# SMB-Server Einstellungen vornehmen
	Set-SmbServerConfiguration -AnnounceServer $true -Force
	Set-SmbServerConfiguration -AutoDisconnectTimeout 0 -Force
	Set-SmbServerConfiguration -EnableLeasing $false -Force
	Set-SmbServerConfiguration -EnableOplocks $false -Force
	Set-SmbServerConfiguration -ServerHidden $false -Force

	HOSTNAME.EXE

	# Mapping von Netzlaufwerk auf Localhost, damit einheitlich ein Netzlaufwerksbuchstabe zur Verfügung steht

	# Druckerfreigaben abklären

}

# Cmdlet zum Prüfen, ob das Script auf einem Windows Server ausgeführt wird
Function Test-WindowsServer() {
	# 1 = Desktop OS
	# 2 = Server OS DC
	# 3 = Server OS Non Domain
	(Get-CimInstance Win32_OperatingSystem).ProductType -ne 1
}

Function Test-EnergySaveSettings {
}

Function Disable-EnergySaveSettings {
	
}

# PeerClient einrichten
Function Install-easyPeerClient {

	# Einstellungen von Internet Explorer Intranet Settings prüfen und
	# das verwendete Netzwerklaufwerk bei den Ausnahmen hinzufügen

	# easy Benutzergruppe einrichten

	# Benutzer einrichten

	Set-SmbClientConfiguration -OplocksDisabled $true -Force
	Set-SmbClientConfiguration -UseOpportunisticLocking $false -Force

	# Mapping einrichten
}

# Benutzergruppe einrichten
Function New-easyGroup {
	[CmdletBinding()]
	Param([String]$Group)

	New-LocalGroup -Name $Group -Description "easy Benutzergruppe" 
}

# easyShare einrichten
Function New-easyShare {
	[CmdletBinding()]
	Param()

	New-Item -ItemType Directory -Path $easySharePath

	# früher war FolderEnumerationMode Unrestricted
	New-SmbShare -Name $easyShare -Path $easySharePath -CachingMode None -Description Beschreibung -FolderEnumerationMode AccessBased -FullAccess $easyGroup, "Administratoren", "SYSTEM" -LeasingMode None

	# TODO: Berechtigungen für easy-Gruppe auch noch setzen: C:\easy -> Eigenschaften->Sicherheit->Erweitert->Berechtigung ändern->
}

Function Test-SMBFirewall {

}

Function Enable-SMBFirewallPorts {

}

Function Disable-SMBFirewallPorts {

}

# prüft, ob SMB1 vorhanden und aktiv ist
Function Test-SMB1Protocol {

	# Unterscheiden zwischen Windows-Server und Windows-Client!!
	# KB Article: 2696547 sowie 4034314
	If (Test-WindowsServer) {
		Get-Windowsfeature -Name FS-SMB1
	} else {
		Get-WindowsOptionalFeature -Online -FeatureName smb1protocol
	}

}

# deaktiviert SMB1
Function Disable-SMB1Protocol {

	If (Test-WindowsServer) {
		Uninstall-WindowsFeature -Name FS-SMB1
	} else {
		Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol
	}

}

# aktiviert SMB1
Function Enable-SMB1Protocol {

	If (Test-WindowsServer) {
		Install-WindowsFeature -Name FS-SMB1
	} else {
		Enable-WindowsOptionalFeature -Online -FeatureName smb1protocol
	}

}

Function Test-ICMPEcho {

	$echoRules = @()
	$echoRules += 'FPS-ICMP4-ERQ-In-NoScope', 'FPS-ICMP4-ERQ-Out-NoScope'
	$echoRules += 'FPS-ICMP6-ERQ-In-NoScope', 'FPS-ICMP6-ERQ-Out-NoScope'
	$echoRules += 'FPS-ICMP4-ERQ-In', 'FPS-ICMP4-ERQ-Out'
	$echoRules += 'FPS-ICMP6-ERQ-In', 'FPS-ICMP6-ERQ-Out'

	Get-NetFirewallRule FPS-ICMP* | Where-Object Enabled -eq $true

}

Function Disable-ICMPEcho {

	Set-NetFirewallRule FPS-ICMP* -Enabled False

	# Set-NetFirewallRule RemoteDesktop-User* -Enabled True
}

Function Enable-ICMPEcho {

	Set-NetFirewallRule FPS-ICMP* -Enabled True

}

Function Refresh-SMBMapping {

}

# Troubleshoot
Function Enable-NetworkTrace {
	[CmdletBinding()]
	Param(
		[String]$TraceFile="$($env:SystemRoot)\$($env:COMPUTERNAME)_Repro_trace.etl",
		[Switch]$KillAllMappings=$True,
		[Switch]$ClearCaches=$True
	)

	# auf Basis von https://support.microsoft.com/en-sg/help/3181029/smb-file-server-share-access-is-unsuccessful-through-dns-cname-alias

	# Logging aktivieren
	Write-Verbose "Tracefile: $TraceFile"
	netsh.exe trace start NetConnection capture=yes maxsize=100 filemode=circular overwrite=yes traceFile=$traceFile
	
	# alle Verbindungen aufheben
	If ($KillAllMappings) {
		NET USE * /DELETE
	}

	If ($ClearCaches) {
		# alle Caches leeren
		IPConfig.exe /FLUSDNS
		NBTSTAT.exe RR
		KLIST.exe /PURGE
		ARP.exe -d
	}

}

Function Disable-NetworkTrace {
	[CmdletBinding()]
	Param(
	)

	netsh.exe trace stop

}

Function Enable-NetworkSharingFirewallPorts {
	[CmdletBinding()]
	Param(
		$Profile="Private"
	)

	$fwRules = Get-NetFirewallProfile -Profile $Profile | Get-NetFirewallRule | Where-Object DisplayGroup -eq $FirewallNetshareGroup
	$fwRules | Enable-NetFirewallRule
	# Set-NetFirewallRule -DisplayGroup "Datei- und Druckerfreigabe"
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
