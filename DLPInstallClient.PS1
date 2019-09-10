# DLPInstallClient.PS1
#

# PeerClient einrichten
Function Install-easyPeerClient {

	# Einstellungen von Internet Explorer Intranet Settings prüfen und
	# das verwendete Netzwerklaufwerk bei den Ausnahmen hinzufügen

	# easy Benutzergruppe einrichten

	# Benutzer einrichten

	Set-SmbClientConfiguration -OplocksDisabled $true -Force
	Set-SmbClientConfiguration -UseOpportunisticLocking $false -Force

	# um sicher zu gehen, dass obige Konfiguration angewendet werden noch den Dienst neu starten
	Restart-Service LanmanWorkstation

	# Mapping einrichten
}

# EOF: DLPInstallClient.PS1