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

	If (-Not (Test-User -Username $easyTester)) {
		# net user $easyTester * /ADD
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
	New-SmbShare -Name $easyShare -Path $easySharePath -CachingMode None -Description Beschreibung -FolderEnumerationMode AccessBased -FullAccess $easyGroup, (Get-AdministratorLocalized), "SYSTEM" -LeasingMode None

	# Berechtigungen für easy-Gruppe auch noch setzen:
	# manuell: C:\easy -> Eigenschaften->Sicherheit->Erweitert->Berechtigung ändern->
	# wir nehmen hier die Gruppe und nicht einen einzelnen Benutzer
	Add-Acl -path $easySharePath -Username $easyGroup

	# wenn bereits eine Freigabe besteht, müssen zumindest diese Parameter gesetzt werden:
	# Get-SmbShare $easyShare|Set-SmbShare -CachingMode None -LeasingMode None
}

# Benutzergruppe einrichten
Function New-easyGroup {
	[CmdletBinding()]
	Param([String]$Group)

	New-LocalGroup -Name $Group -Description "easy Benutzergruppe" 
}

Function New-easyUser {
	[CmdletBinding()]
	Param([String]$Username,
		  [securestring]$Password)

	New-LocalUser -Name $Username -PasswordNeverExpires -Password $Password
	Add-LocalGroupMember -Group $easyGroup -Member $UserName
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

Function Add-Acl {
	[CmdletBinding()]
	Param([String]$path,
		  [String]$Username,
		  [String]$Group)

	$ok = $false
	If ($Username.Length -eq 0 -and $Group.Length -eq 0) {
		throw "Bitte Gruppe oder Benutzer angeben!"
	}
	If ($Username.Length -gt 0 -and $Group.Length -gt 0) {
		throw "Bitte nur Gruppe oder nur Benutzer angeben!"
	}

	If ($Username.Length -gt 0) {
		$ok = Test-User $Username
	}
	If ($Group.Length -gt 0) {
		$ok = Test-Group $Group
	}

	If (Test-Path $path -and $ok) {
		# Get-ACL/Set-ACL Ersatz: http://woshub.com/manage-ntfs-permissions-powershell/
		# https://adamtheautomator.com/how-to-manage-ntfs-permissions-with-powershell/

		$Permission = 'FullControl' # Optionen: [enum]::GetValues('System.Security.AccessControl.FileSystemRights')
		$Inherit = 'ContainerInherit, ObjectInherit' # Optionen: [enum]::GetValues('System.Security.AccessControl.InheritanceFlags')
		$PropFlags = 'None'	# Optionen: [enum]::GetValues('System.Security.AccessControl.PropagationFlags')
		$RuleType = 'Allow' # Optionen: [enum]::GetValues('System.Security.AccessControl.AccessControlType')

		$PermSet = $user, $Permission, $Inherit, $PropFlags, $RuleType

		$Rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $PermSet

		If ($Rule) {
			$acl = Get-Acl -Path $path
			$acl.AddAccessRule($Rule)
			$acl | Set-Acl -Path $path
		}
	} else {
		"Pfad, Gruppe oder Benutzer fehlerhaft!"
	}
}

Function Install-WindowsAdminCenter {
	
	# TODO: to be implemented
	Start https://aka.ms/WACDownload

	# auf den Clients muss jeweils 
	# Enable-PSRemoting -Force ausgeführt werden, dann können die 
	# einzelnen Rechner im WAC hinzugefügt werden

}

Function Invoke-PrepareDelaproForNetwork {
	[CmdletBinding()]
	Param([String]$Netzlaufwerk='N:\'
	)

	# prüfen, ob Netzlaufwerk da ist
	If (Test-Path $Netzlaufwerk) {

		$Dest = "$($Netzlaufwerk)Delapro"
		If (Test-Path $Dest) {
			throw "Zielverzeichnis $Dest exisitiert bereits!"
		} else {
			# dann Delapro von lokal nach Netz kopieren
			Copy-Item C:\Delapro $Dest -Recurse -Verbose
			# TODO: Spielprogramm!!
			# Verknüpfung anpassen
			Set-DelaproShortCutDrive -Netzlaufwerk $Netzlaufwerk
		}
	} else {
		throw "Netzlaufwerk $Netzlaufwerk nicht gefunden"
	}
}

Function Set-DelaproShortCutDrive {
	[CmdletBinding()]
	Param([String]$Netzlaufwerk='N:\'
	)

	If (Test-Path $Netzlaufwerk) {
		$link = Get-FileShortCut Delapro.Lnk
		$Link.WorkingDirectory = $Link.WorkingDirectory('C:\', $Netzlaufwerk)
		$Link.TargetPath = $Link.TargetPath('C:\', $Netzlaufwerk)
		Set-FileShortCut -Shortcut $Link -TargetPath $Link.TargetPath -WorkingDirectory $Link.WorkingDirectory

	}
}
# EOF: DLPInstallServer.PS1