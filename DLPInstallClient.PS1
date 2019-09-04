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

	# Mapping einrichten
}

# EOF: DLPInstallClient.PS1