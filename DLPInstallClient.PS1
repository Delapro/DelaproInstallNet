# DLPInstallClient.PS1
#

# PeerClient einrichten
Function Install-easyPeerClient {

	# Einstellungen von Internet Explorer Intranet Settings prüfen und
	# das verwendete Netzwerklaufwerk bei den Ausnahmen hinzufügen
	If (-Not (Test-NetworkDiscoveryFirewall)) {
		Enable-NetworkDiscoveryFirewallPorts
	}

	# easy Benutzergruppe einrichten

	# Benutzer einrichten

	Set-SmbClientConfiguration -OplocksDisabled $true -Force
	Set-SmbClientConfiguration -UseOpportunisticLocking $false -Force

	# zusätzlich vielleicht, wird für Suchserver benötigt:
	Set-SmbClientConfiguration -DirectoryCacheLifetime 0 -Force
	Set-SmbClientConfiguration -FileInfoCacheLifetime 0 -Force
	Set-SmbClientConfiguration -FileNotFoundCacheLifetime 0 -Force

	# um sicher zu gehen, dass obige Konfiguration angewendet werden noch den Dienst neu starten
	Restart-Service LanmanWorkstation -Force -Verbose

	# Mapping einrichten
}

Function Save-NetDriveRefresh {
	[CmdletBinding()]
	Param(
		[String]$ScriptName='RefreshNetDrive.PS1',
		[String]$DlpDrive='N:',
		[String]$RemotePath="\\$($env:COMPUTERNAME)\easy"
	)

	$script = @"
	# Netzwerkverbindung prüfen und gegebenenfalls wiederherstellen, sollte auf jedem Client lokal gespeichert und mittels Verknüpfung aufrufbar sein.
	# es sollte für die Netzwerkeinrichtung ein NetSetup Unterverzeichnis im Delapro angelegt werden, damit darüber die nötigen Scripte erzeugt werden können und dann am einzelnen Client ausgeführt werden, damit die Einrichtung darüber schneller von statten geht.
	`$localPath = $DLPDrive
	`$remotePath = $RemotePath
	If (((Get-SmbMapping -LocalPath `$localPath -ea SilentlyContinue).Status) -eq `$null) {
	  # es existiert noch kein lokales Laufwerk, also neu anlegen
	  New-SmbMapping -LocalPath `$localPath -RemotePath `$remotePath
	}
	If (((Get-SmbMapping -LocalPath `$localPath -ea SilentlyContinue).Status) -eq 'Unavailable') {
	  # Laufwerk wurde getrennt, also Verbindung neu aufbauen
	  New-SmbMapping -LocalPath `$localPath -RemotePath `$remotePath
	}
	If (((Get-SmbMapping -LocalPath `$localPath -ea SilentlyContinue).Status) -ne 'OK') {
	  # wenn noch nicht erfolgreich, zunächst versuchen die Verbindung zu entfernen und dann neu aufzubauen
	  Remove-SmbMapping -LocalPath `$localPath -Confirm:`$False -Force
	  New-SmbMapping -LocalPath `$localPath -RemotePath `$remotePath
	}
	If (((Get-SmbMapping -LocalPath `$localPath -ea SilentlyContinue).Status) -eq 'OK') {
	  Write-Host -ForegroundColor Green "Verbindung sollte jetzt verfügbar sein!"
	  Start-Sleep -Seconds 1
	} else {
	  Write-Error "Probleme Verbindung zwischen `$localPath und `$remotePath aufzubauen."
	  "Fehler wurden in die Windows Zwischenablage kopiert."
	  $error | Set-Clipboard
	  Start-Sleep -Seconds 30
	}
	
"@

	$script | Set-Content -Path $ScriptName
}


<#


#>

# EOF: DLPInstallClient.PS1