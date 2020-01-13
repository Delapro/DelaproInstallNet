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

# EOF: DLPInstallClient.PS1