# DLPInstallCommon.PS1
#

# Cmdlet zum Prüfen, ob das Script auf einem Windows Server ausgeführt wird
Function Test-WindowsServer() {
	# 1 = Desktop OS
	# 2 = Server OS DC
	# 3 = Server OS Non Domain
	(Get-CimInstance Win32_OperatingSystem).ProductType -ne 1
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

# Troubleshoot
Function Enable-NetworkTrace {
	[CmdletBinding()]
	Param(
		[String]$TraceFile="$($env:SystemRoot)\$($env:COMPUTERNAME)_Repro_trace.etl",
		[Switch]$KillAllMappings=$False,
		[Switch]$ClearCaches=$False
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
		IPConfig.exe /FLUSHDNS
		NBTSTAT.exe -RR
		KLIST.exe PURGE
		ARP.exe -d
	}

}

Function Disable-NetworkTrace {
	[CmdletBinding()]
	Param(
	)

	netsh.exe trace stop

}

Function Test-EnergySaveSettings {

	# Powercfg.exe
	Get-CimInstance -Namespace root/cimv2/power -Classname Win32_PowerPlan

}

Function Disable-EnergySaveSettings {
	
}


Function Test-SMBFirewall {

	# "Datei- und Druckerfreigabe"
	Get-NetFirewallRule -DisplayGroup $FirewallNetshareGroup | Where-Object Enabled -eq $true

}

Function Enable-SMBFirewallPorts {

	Set-NetFirewallRule -DisplayGroup $FirewallNetshareGroup -Enabled True

}

Function Disable-SMBFirewallPorts {

	Set-NetFirewallRule -DisplayGroup $FirewallNetshareGroup -Enabled False

}

# EOF: DLPInstallCommon.PS1