# DLPInstallServer.PS1
#

# PeerServer einrichten
Function Install-easyPeerServer {
	[CmdletBinding()]
	Param(

	)

	# Hostname vom Server setzen?

	# prüfen ob nötige Dienste installiert sind, wenn nicht installieren
	If (-Not (Test-Services)) {
		Install-Services
	}

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

	# Abschalten zur Sicherheit, wenn nicht unbedingt benötigt
	# wenn es benötigt wird, kann man auch bei den Clients gezielt Multichannel abschalten
	Set-SmbServerConfiguration -EnableMultiChannel $false -Force

	# um sicher zu gehen, dass obige Konfiguration angewendet werden noch den Server neu starten
	Restart-Service LanmanServer -Force -Verbose

	HOSTNAME.EXE

	# Mapping von Netzlaufwerk auf Localhost, damit einheitlich ein Netzlaufwerksbuchstabe zur Verfügung steht

	# Druckerfreigaben abklären

}

# easyShare einrichten
Function New-easyShare {
	[CmdletBinding()]
	Param()

	New-Item -ItemType Directory -Path $easySharePath

	# früher war FolderEnumerationMode Unrestricted
	New-SmbShare -Name $easyShare -Path $easySharePath -CachingMode None -Description Beschreibung -FolderEnumerationMode AccessBased -FullAccess $easyGroup, "Administratoren", "SYSTEM" -LeasingMode None

	# TODO: Berechtigungen für easy-Gruppe auch noch setzen: C:\easy -> Eigenschaften->Sicherheit->Erweitert->Berechtigung ändern->

	# wenn bereits eine Freigabe besteht, müssen zumindest diese Parameter gesetzt werden:
	# Get-SmbShare $easyShare|Set-SmbShare -CachingMode None -LeasingMode None
}

# Benutzergruppe einrichten
Function New-easyGroup {
	[CmdletBinding()]
	Param([String]$Group)

	New-LocalGroup -Name $Group -Description "easy Benutzergruppe" 
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

Function Test-Services {
	[CmdletBinding()]
	Param(
	)

	If (Test-WindowsServer) {

	} else {
		
	}
}

Function Install-Services {
	[CmdletBinding()]
	Param(
	)

	If (Test-WindowsServer) {
		# FileAndStorage-Services, File-Services, FS-FileServer, RSAT-File-Services
	} else {

	}
}

# EOF: DLPInstallServer.PS1